[Setup]
AppName=FC26 Conquest
AppVersion=1.0.1
AppVerName=FC26 Conquest 1.0.1
VersionInfoVersion=1.0.1.0
DefaultDirName={commonpf64}\FC26 Conquest
DefaultGroupName=FC26 Conquest
OutputBaseFilename=FC26Conquest-Setup
Compression=lzma2
SolidCompression=yes
UninstallDisplayName=FC26 Conquest
AppPublisher=FC26 Conquest
AppPublisherURL=https://example.com/releases/fc26-conquest
AppSupportURL=https://example.com/support/fc26-conquest
AppUpdatesURL=https://example.com/releases/fc26-conquest
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
OutputDir=..\dist\windows
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\fc26_conquest.exe

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{commonprograms}\FC26 Conquest\FC26 Conquest"; Filename: "{app}\fc26_conquest.exe"; WorkingDir: "{app}"
Name: "{commondesktop}\FC26 Conquest"; Filename: "{app}\fc26_conquest.exe"; WorkingDir: "{app}"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Run]
Filename: "{app}\fc26_conquest.exe"; Description: "Launch FC26 Conquest"; Flags: nowait postinstall skipifsilent

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // The installer creates the desktop shortcut and registers the app for normal Windows uninstall.
  end;
end;
