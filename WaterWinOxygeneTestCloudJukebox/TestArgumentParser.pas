﻿namespace WaterWinOxygeneTestCloudJukebox;

interface

uses
  RemObjects.Elements.EUnit;

type
  TestArgumentParser = public class(Test)
  private
  protected
  public
    method FirstTest;
  end;

implementation

method TestArgumentParser.FirstTest;
begin
  Assert.IsTrue(true);
end;

end.