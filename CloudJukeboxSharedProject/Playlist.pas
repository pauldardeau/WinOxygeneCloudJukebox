namespace CloudJukeboxSharedProject;

interface

type
  PlaylistSong = public class

  public
    Artist: String;
    Album: String;
    Song: String;

    constructor();
  end;


  Playlist = public class

  public
    Name: String;
    Tags: String;
    Songs: List<PlaylistSong>;

    constructor();
  end;

implementation

constructor PlaylistSong;
begin
  Artist := "";
  Album := "";
  Song := "";
end;

constructor Playlist;
begin
  Name := "";
  Tags := "";
  Songs := new List<PlaylistSong>;
end;

end.