﻿namespace WaterWinOxygeneCloudJukebox;

interface

type
  ArgumentParser = public class
  private
    DictAllReservedWords: Dictionary<String, String>;
    DictBoolOptions: Dictionary<String, String>;
    DictIntOptions: Dictionary<String, String>;
    DictStringOptions: Dictionary<String, String>;
    DictCommands: Dictionary<String, String>;
    ListCommands: List<String>;

  public
    constructor();
    method AddOption(O: String; OptionType: String; Help: String);
    method AddOptionalBoolFlag(Flag: String; Help: String);
    method AddOptionalIntArgument(Arg: String; Help: String);
    method AddOptionalStringArgument(Arg: String; Help: String);
    method AddRequiredArgument(Arg: String; Help: String);
    method ParseArgs(Args: ImmutableList<String>): PropertySet;

  end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

constructor ArgumentParser();
begin
  DictAllReservedWords := new Dictionary<String, String>;
  DictBoolOptions := new Dictionary<String, String>;
  DictIntOptions := new Dictionary<String, String>;
  DictStringOptions := new Dictionary<String, String>;
  DictCommands := new Dictionary<String, String>;
  ListCommands := new List<String>;
end;

//*******************************************************************************

method ArgumentParser.AddOption(O: String; OptionType: String; Help: String);
begin
  DictAllReservedWords[O] := OptionType;

  if OptionType = "bool" then
    DictBoolOptions[O] := Help
  else if OptionType = "int" then
    DictIntOptions[O] := Help
  else if OptionType = "string" then
    DictStringOptions[O] := Help;
end;

//*******************************************************************************

method ArgumentParser.AddOptionalBoolFlag(Flag: String; Help: String);
begin
  AddOption(Flag, "bool", Help);
end;

//*******************************************************************************

method ArgumentParser.AddOptionalIntArgument(Arg: String; Help: String);
begin
  AddOption(Arg, "int", Help);
end;

//*******************************************************************************

method ArgumentParser.AddOptionalStringArgument(Arg: String; Help: String);
begin
  AddOption(Arg, "string", Help);
end;

//*******************************************************************************

method ArgumentParser.AddRequiredArgument(Arg: String; Help: String);
begin
  DictCommands[Arg] := Help;
  ListCommands.Add(Arg);
end;

//*******************************************************************************

method ArgumentParser.ParseArgs(Args: ImmutableList<String>): PropertySet;
var
  NumArgs: Integer;
  Working: Boolean;
  I: Integer;
  CommandsFound: Integer;
  Arg: String;
  ArgType: String;
  NextArg: String;
  CommandName: String;

begin
  var ps := new PropertySet;

  NumArgs := Args.Count;
  Working := true;
  I := 0;
  CommandsFound := 0;

  if NumArgs = 0 then
    Working := false;


  while Working do
  begin
    Arg := Args[I];
    if DictAllReservedWords.ContainsKey(Arg) then begin
      ArgType := DictAllReservedWords[Arg];
      Arg := Arg.Substring(2);
      if ArgType = "bool" then begin
        //writeLn(String.Format("adding key={0} value=true", Arg));
        ps.Add(Arg, new PropertyValue(true));
      end
      else if ArgType = "int" then begin
        inc(I);
        if I < NumArgs then begin
          NextArg := Args[I];
          var IntValue := Convert.TryToInt32(NextArg);
          if IntValue <> nil then begin
            //writeLn(String.Format("adding key={0} value={1}", Arg, IntValue));
            ps.Add(Arg, new PropertyValue(IntValue));
          end;
        end
        else begin
          // missing int value
        end;
      end
      else if ArgType = "string" then begin
        inc(I);
        if I < NumArgs then begin
          NextArg := Args[I];
          //writeLn(String.Format("adding key={0} value={1}", Arg, NextArg));
          ps.Add(Arg, new PropertyValue(NextArg));
        end
        else begin
          // missing string value
        end;
      end
      else begin
        // unrecognized type
      end;
    end
    else begin
      if Arg.StartsWith("--") then begin
        // unrecognized option
      end
      else begin
        if CommandsFound < ListCommands.Count then begin
          CommandName := ListCommands[CommandsFound];
          //writeLn(String.Format("adding key={0} value={1}", CommandName, Arg));
          ps.Add(CommandName, new PropertyValue(Arg));
          inc(CommandsFound);
        end
        else begin
          // unrecognized command
        end;
      end;
    end;

    inc(I);
    if I >= NumArgs then begin
      Working := false;
    end;
  end;

  result := ps;
end;

//*******************************************************************************

end.