# FROM ubuntu:22.04
########## zack change image for nvidia cuda toolkit ###########
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04
############################## SYSTEM PARAMETERS ##############################
# * Arguments
ARG USER=initial
ARG GROUP=initial
ARG UID=1000
ARG GID="${UID}"
ARG SHELL=/bin/bash
ARG HARDWARE=x86_64
ARG ENTRYPOINT_FILE=entrypint.sh

# * Env vars for the nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
# ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

# * Setup users and groups
RUN groupadd --gid "${GID}" "${GROUP}" \
    && useradd --gid "${GID}" --uid "${UID}" -ms "${SHELL}" "${USER}" \
    && mkdir -p /etc/sudoers.d \
    && echo "${USER}:x:${UID}:${UID}:${USER},,,:/home/${USER}:${SHELL}" >> /etc/passwd \
    && echo "${USER}:x:${UID}:" >> /etc/group \
    && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USER}" \
    && chmod 0440 "/etc/sudoers.d/${USER}"

# * Replace apt urls
# ? Change to tku
RUN sed -i 's@archive.ubuntu.com@ftp.tku.edu.tw@g' /etc/apt/sources.list
# ? Change to Taiwan
# RUN sed -i 's@archive.ubuntu.com@tw.archive.ubuntu.com@g' /etc/apt/sources.list

# * Time zone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone

# * Copy custom configuration
# ? Requires docker version >= 17.09
COPY --chmod=0775 ./${ENTRYPOINT_FILE} /entrypoint.sh
COPY --chown="${USER}":"${GROUP}" --chmod=0775 config config
# ? docker version < 17.09
# COPY ./${ENTRYPOINT_FILE} /entrypoint.sh
# COPY config config
# RUN sudo chmod 0775 /entrypoint.sh && \
# sudo chown -R "${USER}":"${GROUP}" config \
# && sudo chmod -R 0775 config

############################### INSTALL #######################################
# * Install packages
RUN apt update \
    && apt install -y --no-install-recommends \
    sudo \
    git \
    htop \
    nvtop \
    wget \
    curl \
    psmisc \
    openssh-server \
    usbutils \
    # * Shell
    tmux \
    terminator \
    # * base tools
    udev \
    python3-pip \
    python3-dev \
    python3-setuptools \
    # python3-colcon-common-extensions \
    software-properties-common \
    lsb-release \
    libmodbus-dev \
    # ros-humble-rmw-cyclonedds-cpp \
    # * Work tools
    && apt clean \
    && rm -rf /var/lib/apt/lists/*



# gnome-terminal libcanberra-gtk-module libcanberra-gtk3-module \
# dbus-x11 libglvnd0 libgl1 libglx0 libegl1 libxext6 libx11-6 \
# display dep
# libnss3 libgbm1 libxshmfence1 libdrm2 libx11-xcb1 libxcb-*-dev

ENV DEBIAN_FRONTEND=noninteractive
RUN sudo add-apt-repository universe
RUN sudo apt update
RUN sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key  -o /usr/share/keyrings/ros-archive-keyring.gpg
# RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
RUN sudo apt update
# RUN sudo  apt install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" keyboard-configuration
RUN sudo DEBIAN_FRONTEND=noninteractive apt install -y ros-humble-desktop
#ROS2 Cyclone DDS
RUN sudo apt install -y ros-humble-rmw-cyclonedds-cpp
#colcon depend
RUN sudo apt install -y python3-colcon-common-extensions


##################### ZACK ADD BEGIN ##################################
###################### RealSense #############################
RUN mkdir -p /etc/apt/keyrings
RUN curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp | sudo tee /etc/apt/keyrings/librealsense.pgp > /dev/null
RUN echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" \
    | tee /etc/apt/sources.list.d/librealsense.list


RUN apt update && apt install -y \
    # ros2
    python3-rosdep \
    ros-humble-diagnostic-updater \
    # realsense
    librealsense2-utils \
    librealsense2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN sudo pip3 install setuptools
# opencv-contrib-python==4.11.0.86

#################### PyTorch ######################
RUN pip3 install --ignore-install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

#################### Kinect Azure ###############################
RUN apt-get update && apt install -y \
    libgl1-mesa-dev libsoundio-dev libvulkan-dev libx11-dev libxcursor-dev libxinerama-dev libxrandr-dev libusb-1.0-0-dev libssl-dev libudev-dev mesa-common-dev uuid-dev

WORKDIR /home/${USER}/work/azure
RUN wget https://packages.microsoft.com/ubuntu/18.04/prod/pool/main/k/k4a-tools/k4a-tools_1.4.2_amd64.deb
RUN wget https://packages.microsoft.com/ubuntu/18.04/prod/pool/main/libk/libk4a1.4-dev/libk4a1.4-dev_1.4.2_amd64.deb
RUN wget https://packages.microsoft.com/ubuntu/18.04/prod/pool/main/libk/libk4a1.4/libk4a1.4_1.4.2_amd64.deb
RUN wget http://ftp.de.debian.org/debian/pool/main/libs/libsoundio/libsoundio1_1.1.0-1_amd64.deb

RUN ACCEPT_EULA=Y dpkg -i libk4a1.4_1.4.2_amd64.deb &&\
    dpkg -i libk4a1.4-dev_1.4.2_amd64.deb
RUN dpkg -i libsoundio1_1.1.0-1_amd64.deb
RUN dpkg -i k4a-tools_1.4.2_amd64.deb

RUN rm libk4a1.4_1.4.2_amd64.deb \
    libk4a1.4-dev_1.4.2_amd64.deb \
    libsoundio1_1.1.0-1_amd64.deb \
    k4a-tools_1.4.2_amd64.deb

WORKDIR /home/${USER}/work/azure
RUN git clone https://github.com/microsoft/Azure-Kinect-Sensor-SDK.git
WORKDIR /home/${USER}/work/azure/Azure-Kinect-Sensor-SDK
RUN mkdir -p /etc/udev/rules.d/ && \
    cp ./scripts/99-k4a.rules /etc/udev/rules.d/

RUN rm -rf /home/${USER}/work/azure/Azure-Kinect-Sensor-SDK

WORKDIR /
RUN ./config/pip/pip_setup.sh
##################### ZACK ADD END ##################################

############################## USER CONFIG ####################################
#* Switch user to ${USER}
USER ${USER}

RUN ./config/shell/bash_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/terminator/terminator_setup.sh "${USER}" "${GROUP}" \
    && ./config/shell/tmux/tmux_setup.sh "${USER}" "${GROUP}" \
    && sudo rm -rf /config

RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
RUN echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc

# * Switch workspace to ~/work
RUN sudo mkdir -p /home/"${USER}"/work
WORKDIR /home/"${USER}"/work

# * Make SSH available
EXPOSE 22

ENTRYPOINT [ "/entrypoint.sh", "terminator" ]
# ENTRYPOINT [ "/entrypoint.sh", "tmux" ]
# ENTRYPOINT [ "/entrypoint.sh", "bash" ]
# ENTRYPOINT [ "/entrypoint.sh" ]
