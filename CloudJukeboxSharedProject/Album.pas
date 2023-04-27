namespace CloudJukeboxSharedProject;

interface

type
  AlbumTrack = public class

  public
    Number: Integer;
    Title: String;
    ObjectName: String;
    TrackLength: String;

    constructor();
  end;


  Album = public class

  public
    Artist: String;
    AlbumName: String;
    AlbumArt: String;
    Year: String;
    Genres: List<String>;
    AlbumType: String;
    Wiki: String;
    Tracks: List<AlbumTrack>;

    constructor();
  end;

implementation

constructor AlbumTrack;
begin
  Number := 0;
  Title := "";
  ObjectName := "";
  TrackLength := "";
end;

constructor Album;
begin
  Artist := "";
  AlbumName := "";
  AlbumArt := "";
  Year := "";
  Genres := new List<String>;
  AlbumType := "";
  Wiki := "";
  Tracks := new List<AlbumTrack>;
end;

end.