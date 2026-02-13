#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

#ifndef MyStageDir
  #error MyStageDir must point to the staged installer bundle.
#endif

#ifndef MyAppExe
  #define MyAppExe "client.exe"
#endif

#define AppName "Slipstream"

[Setup]
AppId={{E58F4BA6-4B21-45D6-997F-8390D9A16E9C}
AppName={#AppName}
AppVersion={#MyAppVersion}
AppPublisher=Slipstream
DefaultDirName={autopf}\\Slipstream
DefaultGroupName=Slipstream
DisableProgramGroupPage=yes
OutputBaseFilename=Slipstream-Setup-{#MyAppVersion}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\\{#MyAppExe}
PrivilegesRequired=admin
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:";
Name: "autostart"; Description: "Auto-start local dashboard service at user logon"; Flags: unchecked
Name: "driver"; Description: "Install Slipstream USB driver (if bundled)"; Flags: unchecked

[Files]
Source: "{#MyStageDir}\\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\\Slipstream"; Filename: "{app}\\{#MyAppExe}"
Name: "{autodesktop}\\Slipstream"; Filename: "{app}\\{#MyAppExe}"; Tasks: desktopicon

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File \"{app}\\scripts\\windows\\install-autostart.ps1\" -InstallRoot \"{app}\""; Flags: runhidden waituntilterminated; Tasks: autostart; StatusMsg: "Configuring startup service..."
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File \"{app}\\scripts\\windows\\install-driver.ps1\" -InstallRoot \"{app}\""; Flags: runhidden waituntilterminated; Tasks: driver; StatusMsg: "Installing driver..."
Filename: "{app}\\{#MyAppExe}"; Description: "Launch Slipstream"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File \"{app}\\scripts\\windows\\uninstall-autostart.ps1\""; Flags: runhidden waituntilterminated
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File \"{app}\\scripts\\windows\\uninstall-driver.ps1\" -InstallRoot \"{app}\""; Flags: runhidden waituntilterminated
