wsl --install

#OR
#dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
#INSTALL WSL FROM THE STORE FOR LATEST VERSION, i.e. v2
wsl --set-default-version 2

wsl --version

#View all
wsl --list

#View running
wsl -l -v

#export
wsl --export Ubuntu s:\scratch\ubuntuwsl.tar
wsl --unregister Ubuntu

wsl --import Ubuntu d:\images\Ubuntu d:\scratch\ubuntuwsl.tar

wsl --list
wsl --set-default Ubuntu

wsl -d Ubuntu

wsl --shutdown
