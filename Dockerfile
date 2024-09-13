FROM ubuntu:22.04
RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install software-properties-common curl -y
RUN add-apt-repository ppa:deadsnakes/ppa -y && apt update -y
RUN apt-get install python3-pip -y
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg && \
    sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs 2>/dev/null)-prod $(lsb_release -cs 2>/dev/null) main" > /etc/apt/sources.list.d/dotnetdev.list'
RUN apt-get update -y && apt-get install -y azure-functions-core-tools-4
RUN useradd -ms /bin/bash ubuntu
USER ubuntu
WORKDIR /home/ubuntu
RUN echo "export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1" >> /home/ubuntu/.bash_profile
RUN echo "export FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT=1" >> /home/ubuntu/.bash_profile
ENTRYPOINT ["bash"]
