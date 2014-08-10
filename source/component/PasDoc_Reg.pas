{ @abstract(Registers the PasDoc components into the IDE. )
  @author(Ralf Junker (delphi@zeitungsjunge.de))
  @cvs($Date: 2003/04/30 17:35:26 $)
  @author(Johannes Berg <johannes@sipsolutions.de> }

unit PasDoc_Reg;

interface

{ Registers the PasDoc components into the IDE. }
procedure Register;

implementation

uses
  Classes,
  PasDoc,
  PasDoc_GenHtml;

procedure Register;
begin
  RegisterComponents('PasDoc', [TPasDoc, THTMLDocGenerator]);
end;

end.
