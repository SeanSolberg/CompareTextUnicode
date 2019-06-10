program UnicodeDataProcessor;

uses
  Vcl.Forms,
  UnicodeProcessFrm in 'UnicodeProcessFrm.pas' {Form34},
  unicodedata in 'unicodedata.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm34, Form34);
  Application.Run;
end.
