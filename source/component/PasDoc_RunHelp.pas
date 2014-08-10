{ @cvs($Date: 2003/05/02 22:34:52 $)
  @author(Johannes Berg <johannes@sipsolutions.de>)
  @abstract(help running programs)
  To be used for spell-checking }
unit PasDoc_RunHelp;

interface
{$IFDEF LINUX}
  {$IFNDEF FPC}
  uses Libc;
  {$ELSE}
  uses linux;
  {$ENDIF}
{$ELSE}
  {$IFDEF WIN32}
  uses Windows;
  {$ENDIF}
{$ENDIF}

type
  TRunRecord = record // opaque record (platform dependent)
{$IFDEF LINUX}
{$ENDIF}
  end;

function RunProgram(const AName: string; args: string): TRunRecord;
procedure WriteLine(const ALine: string; const ARR: TRunRecord);
procedure CloseProgram(var ARR: TRunRecord);
function ReadLine(const ARR: TRunRecord): string;

implementation
uses
  SysUtils;

{$IFDEF FPC}
type
  TPipeDescriptors = record
    ReadDes, WriteDes: Integer;
  end;
{$ENDIF}

{$IFDEF LINUX}
function RunProgram(const AName: string; args: string): TRunRecord;
begin
end;


procedure WriteLine(const ALine: string; const ARR: TRunRecord);
begin
end;

procedure CloseProgram(var ARR: TRunRecord);
begin
end;

function ReadLine(const ARR: TRunRecord): string;
begin
end;
{$ELSE}
function RunProgram(const AName: string; args: string): TRunRecord;
begin
  raise Exception.Create('not implemented');
end;

procedure WriteLine(const ALine: string; const ARR: TRunRecord);
begin
  raise Exception.Create('not implemented');
end;

procedure CloseProgram(var ARR: TRunRecord);
begin
  raise Exception.Create('not implemented');
end;

function ReadLine(const ARR: TRunRecord): string;
begin
  raise Exception.Create('not implemented');
end;

{$ENDIF}
end.
