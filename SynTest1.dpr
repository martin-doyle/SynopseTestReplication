{{
—————————————————————————————————————————————————————————————————————————
 Project : Synopse Replication Test

 Using mORMot
     Synopse mORMot framework. Copyright (C) 2017 Arnaud Bouchez
     Synopse Informatique - http://synopse.info

  Module : SynTest1

  Last modified
    Date : 22.04.2017 09:03:45
  Author : Martin Doyle
   Email : martin.doyle@dakata.de
—————————————————————————————————————————————————————————————————————————
}
program SynTest1;

{$APPTYPE CONSOLE}

uses
  {$I SynDprUses.inc} // use FastMM4 on older Delphi, or set FPC threads
  SynTestTest1;

begin
  with TTestSuite.Create do
  try
    Run;
    readln;
  finally
    Free;
  end;
end.
