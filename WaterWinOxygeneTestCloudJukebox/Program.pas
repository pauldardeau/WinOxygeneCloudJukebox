namespace WaterWinOxygeneTestCloudJukebox;

uses
  RemObjects.Elements.EUnit;

type
  Program = public static class
  private

    method Main(args: array of String): Int32; public;
    begin
      var lTests := Discovery.DiscoverTests();
      Runner.RunTests(lTests); //, Runner.DefaultListener);
    end;

  end;

end.