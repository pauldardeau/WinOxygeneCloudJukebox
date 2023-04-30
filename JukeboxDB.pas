namespace WaterWinOxygeneCloudJukebox;

uses
  CloudJukeboxSharedProject;

interface

type
  JukeboxDB = public class
  private
    DebugPrint: Boolean;
    DbConnection: ^sqlite3.sqlite3;
    MetadataDbFilePath: String;
    InTransaction: Boolean;

  public
    constructor(aMetadataDbFilePath: String;
                aDebugPrint: Boolean);
    method IsOpen: Boolean;
    method Open: Boolean;
    method Close: Boolean;
    method Enter: Boolean;
    method Leave;
    method PrepareStatement(SqlStatement: String): ^sqlite3.sqlite3_stmt;
    method StepStatement(Statement: ^sqlite3.sqlite3_stmt): Boolean;
    method ExecuteUpdate(SqlStatement: String;
                         out RowsAffectedCount: Integer): Boolean;
    method ExecuteUpdate(SqlStatement: String;
                         out RowsAffectedCount: Integer;
                         Arguments: PropertyList): Boolean;
    method BeginTransaction: Boolean;
    method BeginDeferredTransaction: Boolean;
    method Rollback: Boolean;
    method Commit: Boolean;
    method CreateTable(SqlStatement: String): Boolean;
    method CreateTables: Boolean;
    method HaveTables: Boolean;
    method GetPlaylist(PlaylistName: String): String;
    method SongsForQueryResults(Statement: ^sqlite3.sqlite3_stmt): List<SongMetadata>;
    method RetrieveSong(FileName: String): SongMetadata;
    method InsertPlaylist(PlUid: String; PlName: String; PlDesc: String): Boolean;
    method DeletePlaylist(PlName: String): Boolean;
    method InsertSong(Song: SongMetadata): Boolean;
    method UpdateSong(Song: SongMetadata): Boolean;
    method StoreSongMetadata(Song: SongMetadata): Boolean;
    method SqlWhereClause: String;
    method RetrieveSongs(Artist: String; Album: String): List<SongMetadata>;
    method SongsForArtist(ArtistName: String): List<SongMetadata>;
    method ShowListings;
    method ShowArtists;
    method ShowGenres;
    method ShowAlbums;
    method ShowPlaylists;
    method DeleteSong(SongUid: String): Boolean;
    method MakeStringFromCString(CString: ^Byte): String;
  end;

//*******************************************************************************
//*******************************************************************************

implementation

//*******************************************************************************

constructor JukeboxDB(aMetadataDbFilePath: String;
                      aDebugPrint: Boolean);
begin
  DebugPrint := true; //debugPrint;
  DbConnection := nil;
  InTransaction := false;
  if aMetadataDbFilePath.Length > 0 then
    MetadataDbFilePath := aMetadataDbFilePath
  else
    MetadataDbFilePath := "jukebox_db.sqlite3";
end;

//*******************************************************************************

method JukeboxDB.IsOpen: Boolean;
begin
  result := DbConnection <> nil;
end;

//*******************************************************************************

method JukeboxDB.Open: Boolean;
begin
  Close;
  var OpenSuccess := false;

  if sqlite3.sqlite3_open(MetadataDbFilePath, @DbConnection) <> sqlite3.SQLITE_OK then begin
    writeLn("error: unable to open SQLite db");
  end
  else begin
    if not HaveTables then begin
      OpenSuccess := CreateTables;
      if not OpenSuccess then begin
        writeLn("error: unable to create all tables");
      end;
    end
    else begin
      OpenSuccess := true;
    end;
  end;
  exit OpenSuccess;
end;

//*******************************************************************************

method JukeboxDB.Close: Boolean;
begin
  var DidClose := false;
  if DbConnection <> nil then begin
    sqlite3.sqlite3_close(DbConnection);
    DbConnection := nil;
    DidClose := true;
  end;
  exit DidClose;
end;

//*******************************************************************************

method JukeboxDB.Enter: Boolean;
begin
  // look for stored metadata in the storage system
  if Open() then begin
    if DbConnection <> nil then begin
      if DebugPrint then begin
        writeLn("have db connection");
      end;
    end;
  end
  else begin
    writeLn("unable to connect to database");
    DbConnection := nil;
  end;

  result := DbConnection <> nil;
end;

//*******************************************************************************

method JukeboxDB.Leave;
begin
  if DbConnection <> nil then begin
    sqlite3.sqlite3_close(DbConnection);
    DbConnection := nil;
  end;
end;

//*******************************************************************************

method JukeboxDB.PrepareStatement(SqlStatement: String): ^sqlite3.sqlite3_stmt;
begin
  var Statement: ^sqlite3.sqlite3_stmt := nil;
  if DbConnection <> nil then begin
    const rc = sqlite3.sqlite3_prepare_v2(DbConnection,
                                          SqlStatement,
                                          -1,
                                          @Statement,
                                          nil);
    if rc = sqlite3.SQLITE_OK then begin
      exit Statement;
    end
    else begin
      writeLn("error: prepare of sql failed: {0}", SqlStatement);
    end;
  end;
  exit nil;
end;

//*******************************************************************************

method JukeboxDB.StepStatement(Statement: ^sqlite3.sqlite3_stmt): Boolean;
begin
  var DidSucceed := false;
  if (DbConnection <> nil) and (Statement <> nil) then begin
    const rc = sqlite3.sqlite3_step(Statement);
    if rc = sqlite3.SQLITE_DONE then begin
      DidSucceed := true;
    end;
  end;
  exit DidSucceed;
end;

//*******************************************************************************

method JukeboxDB.ExecuteUpdate(SqlStatement: String;
                               out RowsAffectedCount: Integer): Boolean;
begin
  if DbConnection = nil then begin
    RowsAffectedCount := 0;
    writeLn("error: no database connection");
    exit false;
  end;

  const Stmt = PrepareStatement(SqlStatement);
  if Stmt = nil then begin
    RowsAffectedCount := 0;
    exit false;
  end;

  const queryCount = sqlite3.sqlite3_bind_parameter_count(Stmt);

  if 0 <> queryCount then begin
    writeLn("Error: the bind count is not correct for the #" +
            " of variables ({0}) (executeUpdate)",
            SqlStatement);
    sqlite3.sqlite3_finalize(Stmt);
    RowsAffectedCount := 0;
    exit false;
  end;

  var rc := sqlite3.sqlite3_step(Stmt);

  if (sqlite3.SQLITE_DONE = rc) or (sqlite3.SQLITE_ROW = rc) then begin
    // all is well, let's return.
  end
  else if sqlite3.SQLITE_ERROR = rc then begin
    writeLn("Error calling sqlite3_step ({0}) SQLITE_ERROR", rc);
    writeLn("DB Query: {0}", SqlStatement);
  end
  else if sqlite3.SQLITE_MISUSE = rc then begin
    writeLn("Error calling sqlite3_step ({0}) SQLITE_MISUSE", rc);
    writeLn("DB Query: {0}", SqlStatement);
  end
  else begin
    writeLn("Unknown error calling sqlite3_step ({0}) other error", rc);
    writeLn("DB Query: {0}", SqlStatement);
  end;

  assert(rc <> sqlite3.SQLITE_ROW);

  rc := sqlite3.sqlite3_finalize(Stmt);

  const SqlSuccess = (rc = sqlite3.SQLITE_OK);

  if SqlSuccess then begin
    RowsAffectedCount := sqlite3.sqlite3_changes(DbConnection);
  end
  else begin
    RowsAffectedCount := 0;
  end;

  exit SqlSuccess;
end;

//*******************************************************************************

method JukeboxDB.ExecuteUpdate(SqlStatement: String;
                               out RowsAffectedCount: Integer;
                               Arguments: PropertyList): Boolean;
begin
  if DbConnection = nil then begin
    RowsAffectedCount := 0;
    writeLn("error: no database connection");
    exit false;
  end;

  const Stmt = PrepareStatement(SqlStatement);
  if Stmt = nil then begin
    RowsAffectedCount := 0;
    exit false;
  end;

  const QueryCount = sqlite3.sqlite3_bind_parameter_count(Stmt);

  if Arguments.Count() <> QueryCount then begin
    writeLn("Error: the bind count is not correct for the #" +
            " of variables ({0}) (executeUpdate)",
            SqlStatement);
    sqlite3.sqlite3_finalize(Stmt);
    RowsAffectedCount := 0;
    exit false;
  end;

  var argIndex := 0;
  var rc: Integer;

  for each arg in Arguments.ListProps do begin
    inc(argIndex);
    if arg.IsInt() then
      rc := sqlite3.sqlite3_bind_int(Stmt, argIndex, arg.GetIntValue())
    else if arg.IsLong() then
      rc := sqlite3.sqlite3_bind_int64(Stmt, argIndex, arg.GetLongValue())
    else if arg.IsULong() then begin
      const longValue = Int64(arg.GetULongValue());
      rc := sqlite3.sqlite3_bind_int64(Stmt, argIndex, longValue);
    end
    else if arg.IsBool() then begin
      if arg.GetBoolValue() then
        rc := sqlite3.sqlite3_bind_int(Stmt, argIndex, 1)
      else
        rc := sqlite3.sqlite3_bind_int(Stmt, argIndex, 0);
    end
    else if arg.IsString() then
      rc := sqlite3.sqlite3_bind_text(Stmt, argIndex, arg.GetStringValue(), -1, nil)
    else if arg.IsDouble() then
      rc := sqlite3.sqlite3_bind_double(Stmt, argIndex, arg.GetDoubleValue())
    else if arg.IsNull() then
      rc := sqlite3.sqlite3_bind_null(Stmt, argIndex);

    if rc <> sqlite3.SQLITE_OK then begin
      sqlite3.sqlite3_finalize(Stmt);
      writeLn("Error: unable to bind argument {0}, rc={1}", argIndex, rc);
      exit false;
    end;
  end;

  rc := sqlite3.sqlite3_step(Stmt);

  if (sqlite3.SQLITE_DONE = rc) or (sqlite3.SQLITE_ROW = rc) then begin
    // all is well, let's return.
  end
  else if sqlite3.SQLITE_ERROR = rc then begin
    writeLn("Error calling sqlite3_step ({0}) SQLITE_ERROR", rc);
    writeLn("DB Query: {0}", SqlStatement);
  end
  else if sqlite3.SQLITE_MISUSE = rc then begin
    writeLn("Error calling sqlite3_step ({0}) SQLITE_MISUSE", rc);
    writeLn("DB Query: {0}", SqlStatement);
  end
  else begin
    writeLn("Unknown error calling sqlite3_step ({0}) other error", rc);
    writeLn("DB Query: {0}", SqlStatement);
  end;

  assert(rc <> sqlite3.SQLITE_ROW);

  rc := sqlite3.sqlite3_finalize(Stmt);

  const SqlSuccess = (rc = sqlite3.SQLITE_OK);

  if SqlSuccess then begin
    RowsAffectedCount := sqlite3.sqlite3_changes(DbConnection);
  end
  else begin
    RowsAffectedCount := 0;
  end;

  exit SqlSuccess;
end;

//*******************************************************************************

method JukeboxDB.BeginTransaction: Boolean;
begin
  if InTransaction then begin
    writeLn("error: BeginTransaction called when already in transaction");
    exit false;
  end
  else begin
    InTransaction := true;
    var RowsAffected: Int32 := 0;
    exit ExecuteUpdate("BEGIN EXCLUSIVE TRANSACTION;", out RowsAffected);
  end;
end;

//*******************************************************************************

method JukeboxDB.BeginDeferredTransaction: Boolean;
begin
  if InTransaction then begin
    writeLn("error: BeginDeferredTransaction called when already in transaction");
    exit false;
  end
  else begin
    InTransaction := true;
    var RowsAffected: Int32 := 0;
    exit ExecuteUpdate("BEGIN DEFERRED TRANSACTION;", out RowsAffected);
  end;
end;

//*******************************************************************************

method JukeboxDB.Rollback: Boolean;
begin
  if not InTransaction then begin
    writeLn("error: Rollback called when not in transaction");
    exit false;
  end
  else begin
    var RowsAffected: Int32 := 0;
    result := ExecuteUpdate("ROLLBACK TRANSACTION;", out RowsAffected);
    InTransaction := false;
  end;
end;

//*******************************************************************************

method JukeboxDB.Commit: Boolean;
begin
  if not InTransaction then begin
    writeLn("error: Commit called when not in transaction");
    exit false;
  end
  else begin
    var RowsAffected: Int32 := 0;
    result := ExecuteUpdate("COMMIT TRANSACTION;", out RowsAffected);
    InTransaction := false;
  end;
end;

//*******************************************************************************

method JukeboxDB.CreateTable(SqlStatement: String): Boolean;
begin
  var DidSucceed := false;
  if DbConnection <> nil then begin
    const Stmt = PrepareStatement(SqlStatement);
    if Stmt = nil then begin
      writeLn("prepare of statement failed: {0}", SqlStatement);
      exit false;
    end;

    try
      if not StepStatement(Stmt) then begin
        writeLn("error: creation of table failed");
        writeLn(SqlStatement);
      end
      else begin
        DidSucceed := true;
      end;
    finally
      sqlite3.sqlite3_finalize(Stmt);
    end;
  end;
  exit DidSucceed;
end;

//*******************************************************************************

method JukeboxDB.CreateTables: Boolean;
begin
  var DidSucceed := false;
  if DbConnection <> nil then begin
    if DebugPrint then begin
      writeLn("creating tables");
    end;

    const createGenreTable = "CREATE TABLE genre (" +
                             "genre_uid TEXT UNIQUE NOT NULL, " +
                             "genre_name TEXT UNIQUE NOT NULL, " +
                             "genre_description TEXT);";

    const createArtistTable = "CREATE TABLE artist (" +
                              "artist_uid TEXT UNIQUE NOT NULL," +
                              "artist_name TEXT UNIQUE NOT NULL," +
                              "artist_description TEXT)";

    const createAlbumTable = "CREATE TABLE album (" +
                             "album_uid TEXT UNIQUE NOT NULL," +
                             "album_name TEXT UNIQUE NOT NULL," +
                             "album_description TEXT," +
                             "artist_uid TEXT NOT NULL REFERENCES artist(artist_uid)," +
                             "genre_uid TEXT REFERENCES genre(genre_uid))";

    const createSongTable = "CREATE TABLE song (" +
                            "song_uid TEXT UNIQUE NOT NULL," +
                            "file_time TEXT," +
                            "origin_file_size INTEGER," +
                            "stored_file_size INTEGER," +
                            "pad_char_count INTEGER," +
                            "artist_name TEXT," +
                            "artist_uid TEXT REFERENCES artist(artist_uid)," +
                            "song_name TEXT NOT NULL," +
                            "md5_hash TEXT NOT NULL," +
                            "compressed INTEGER," +
                            "encrypted INTEGER," +
                            "container_name TEXT NOT NULL," +
                            "object_name TEXT NOT NULL," +
                            "album_uid TEXT REFERENCES album(album_uid))";

    const createPlaylistTable = "CREATE TABLE playlist (" +
                                "playlist_uid TEXT UNIQUE NOT NULL," +
                                "playlist_name TEXT UNIQUE NOT NULL," +
                                "playlist_description TEXT)";

    const createPlaylistSongTable = "CREATE TABLE playlist_song (" +
                                    "playlist_song_uid TEXT UNIQUE NOT NULL," +
                                    "playlist_uid TEXT NOT NULL REFERENCES playlist(playlist_uid)," +
                                    "song_uid TEXT NOT NULL REFERENCES song(song_uid))";

    DidSucceed := CreateTable(createGenreTable) and
                  CreateTable(createArtistTable) and
                  CreateTable(createAlbumTable) and
                  CreateTable(createSongTable) and
                  CreateTable(createPlaylistTable) and
                  CreateTable(createPlaylistSongTable);
  end;

  exit DidSucceed;
end;

//*******************************************************************************

method JukeboxDB.HaveTables: Boolean;
begin
  var HaveTablesInDb := false;
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT COUNT(*) " +
                     "FROM sqlite_master " +
                     "WHERE type='table' AND name='song'";
    const Stmt = PrepareStatement(SqlQuery);
    if Stmt = nil then begin
      exit false;
    end;

    try
      if sqlite3.sqlite3_step(Stmt) = sqlite3.SQLITE_ROW then begin
        const Count = sqlite3.sqlite3_column_int(Stmt, 0);
        if Count > 0 then begin
          HaveTablesInDb := true;
        end;
      end;
    finally
      sqlite3.sqlite3_finalize(Stmt);
    end;
  end;

  exit HaveTablesInDb;
end;

//*******************************************************************************

method JukeboxDB.GetPlaylist(PlaylistName: String): String;
begin
  var PlObject: String := nil;

  if PlaylistName.Length > 0 then begin
    const SqlQuery = "SELECT playlist_uid " +
                     "FROM playlist " +
                     "WHERE playlist_name = ?";
    const Stmt = PrepareStatement(SqlQuery);
    if Stmt = nil then begin
      exit nil;
    end;

    try
      if sqlite3.sqlite3_step(Stmt) = sqlite3.SQLITE_ROW then begin
        const QueryResultCol1 = sqlite3.sqlite3_column_text(Stmt, 0);
        if QueryResultCol1 <> nil then begin
          PlObject := MakeStringFromCString(QueryResultCol1);
        end;
      end;
    finally
      sqlite3.sqlite3_finalize(Stmt);
    end;
  end;
  exit PlObject;
end;

//*******************************************************************************

method JukeboxDB.SongsForQueryResults(Statement: ^sqlite3.sqlite3_stmt): List<SongMetadata>;
begin
  const ResultSongs = new List<SongMetadata>();

  var rc := sqlite3.sqlite3_step(Statement);

  while (rc <> sqlite3.SQLITE_DONE) and (rc <> sqlite3.SQLITE_OK) do begin
    const song = new SongMetadata();
    song.Fm.FileUid := MakeStringFromCString(sqlite3.sqlite3_column_text(Statement, 0));
    song.Fm.FileTime := MakeStringFromCString(sqlite3.sqlite3_column_text(Statement, 1));
    song.Fm.OriginFileSize := sqlite3.sqlite3_column_int64(Statement, 2);
    song.Fm.StoredFileSize := sqlite3.sqlite3_column_int64(Statement, 3);
    song.Fm.PadCharCount := sqlite3.sqlite3_column_int(Statement, 4);
    song.ArtistName := MakeStringFromCString(sqlite3.sqlite3_column_text(Statement, 5));
    song.ArtistUid := MakeStringFromCString(sqlite3.sqlite3_column_text(Statement, 6));
    song.SongName := MakeStringFromCString(sqlite3.sqlite3_column_text(Statement, 7));
    song.Fm.Md5Hash := MakeStringFromCString(sqlite3.sqlite3_column_text(Statement, 8));
    song.Fm.Compressed := (sqlite3.sqlite3_column_int(Statement, 9) = 1);
    song.Fm.Encrypted := (sqlite3.sqlite3_column_int(Statement, 10) = 1);
    song.Fm.ContainerName := MakeStringFromCString(sqlite3.sqlite3_column_text(Statement, 11));
    song.Fm.ObjectName := MakeStringFromCString(sqlite3.sqlite3_column_text(Statement, 12));
    song.AlbumUid := MakeStringFromCString(sqlite3.sqlite3_column_text(Statement, 13));

    ResultSongs.Add(song);
    rc := sqlite3.sqlite3_step(Statement);
  end;

  exit ResultSongs;
end;

//*******************************************************************************

method JukeboxDB.RetrieveSong(FileName: String): SongMetadata;
begin
  var Song: SongMetadata := nil;

  if DbConnection <> nil then begin
    const SqlQuery = "SELECT song_uid," +
                            "file_time," +
                            "origin_file_size," +
                            "stored_file_size," +
                            "pad_char_count," +
                            "artist_name," +
                            "artist_uid," +
                            "song_name," +
                            "md5_hash," +
                            "compressed," +
                            "encrypted," +
                            "container_name," +
                            "object_name," +
                            "album_uid " +
                     "FROM song " +
                     "WHERE song_uid = ?";
    const Stmt = PrepareStatement(SqlQuery);
    if Stmt = nil then begin
      exit nil;
    end;

    const SongResults = SongsForQueryResults(Stmt);
    if SongResults.Count > 0 then begin
      Song := SongResults[0];
    end;
    sqlite3.sqlite3_finalize(Stmt);
  end;
  exit Song;
end;

//*******************************************************************************

method JukeboxDB.InsertPlaylist(PlUid: String;
                                PlName: String;
                                PlDesc: String): Boolean;
begin
  var InsertSuccess := false;

  if (DbConnection <> nil) and
     (PlUid.Length > 0) and
     (PlName.Length > 0) then begin

    if not BeginTransaction then begin
      exit false;
    end;

    const SqlStatement = "INSERT INTO playlist VALUES (?,?,?)";

    const Args = new PropertyList;
    Args.Append(new PropertyValue(PlUid));
    Args.Append(new PropertyValue(PlName));
    Args.Append(new PropertyValue(PlDesc));
    var RowsAffected: Int32 := 0;

    if not ExecuteUpdate(SqlStatement, out RowsAffected, Args) then begin
      Rollback;
    end
    else begin
      InsertSuccess := Commit;
    end;
  end;

  exit InsertSuccess;
end;

//*******************************************************************************

method JukeboxDB.DeletePlaylist(PlName: String): Boolean;
begin
  var DeleteSuccess := false;

  if (DbConnection <> nil) and (PlName.Length > 0) then begin
    if not BeginTransaction then begin
      exit false;
    end;

    const SqlQuery = "DELETE FROM playlist WHERE playlist_name = ?";

    const Args = new PropertyList;
    Args.Append(new PropertyValue(PlName));
    var RowsAffected: Int32 := 0;

    if not ExecuteUpdate(SqlQuery, out RowsAffected, Args) then begin
      Rollback;
    end
    else begin
      DeleteSuccess := Commit;
    end;
  end;

  exit DeleteSuccess;
end;

//*******************************************************************************

method JukeboxDB.InsertSong(Song: SongMetadata): Boolean;
begin
  var InsertSuccess := false;

  if DbConnection <> nil then begin
    if not BeginTransaction() then begin
      exit false;
    end;

    const Args = new PropertyList();
    Args.Append(new PropertyValue(Song.Fm.FileUid));
    Args.Append(new PropertyValue(Song.Fm.FileTime));
    Args.Append(new PropertyValue(Song.Fm.OriginFileSize));
    Args.Append(new PropertyValue(Song.Fm.StoredFileSize));
    Args.Append(new PropertyValue(Song.Fm.PadCharCount));
    Args.Append(new PropertyValue(Song.ArtistName));
    Args.Append(new PropertyValue(""));
    Args.Append(new PropertyValue(Song.SongName));
    Args.Append(new PropertyValue(Song.Fm.Md5Hash));
    Args.Append(new PropertyValue(Song.Fm.Compressed));
    Args.Append(new PropertyValue(Song.Fm.Encrypted));
    Args.Append(new PropertyValue(Song.Fm.ContainerName));
    Args.Append(new PropertyValue(Song.Fm.ObjectName));
    Args.Append(new PropertyValue(Song.AlbumUid));

    const SqlQuery = "INSERT INTO song VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
    var RowsAffected: Int32 := 0;

    if not ExecuteUpdate(SqlQuery, out RowsAffected, Args) then begin
      Rollback();
    end
    else begin
      InsertSuccess := Commit();
    end;
  end;

  exit InsertSuccess;
end;

//*******************************************************************************

method JukeboxDB.UpdateSong(Song: SongMetadata): Boolean;
begin
  var UpdateSuccess := false;

  if (DbConnection <> nil) and (Song.Fm.FileUid.Length > 0) then begin
    if not BeginTransaction() then begin
      exit false;
    end;

    const Args = new PropertyList();
    Args.Append(new PropertyValue(Song.Fm.FileTime));
    Args.Append(new PropertyValue(Song.Fm.OriginFileSize));
    Args.Append(new PropertyValue(Song.Fm.StoredFileSize));
    Args.Append(new PropertyValue(Song.Fm.PadCharCount));
    Args.Append(new PropertyValue(Song.ArtistName));
    Args.Append(new PropertyValue(""));
    Args.Append(new PropertyValue(Song.SongName));
    Args.Append(new PropertyValue(Song.Fm.Md5Hash));
    Args.Append(new PropertyValue(Song.Fm.Compressed));
    Args.Append(new PropertyValue(Song.Fm.Encrypted));
    Args.Append(new PropertyValue(Song.Fm.ContainerName));
    Args.Append(new PropertyValue(Song.Fm.ObjectName));
    Args.Append(new PropertyValue(Song.AlbumUid));
    Args.Append(new PropertyValue(Song.Fm.FileUid));

    var RowsAffected: Int32 := 0;

    const SqlQuery = "UPDATE song " +
                     "SET file_time=?," +
                         "origin_file_size=?," +
                         "stored_file_size=?," +
                         "pad_char_count=?," +
                         "artist_name=?," +
                         "artist_uid=?," +
                         "song_name=?," +
                         "md5_hash=?," +
                         "compressed=?," +
                         "encrypted=?," +
                         "container_name=?," +
                         "object_name=?," +
                         "album_uid=? " +
                     "WHERE song_uid = ?";

    if not ExecuteUpdate(SqlQuery, out RowsAffected, Args) then begin
      Rollback();
    end
    else begin
      UpdateSuccess := Commit();
    end;
  end;

  exit UpdateSuccess;
end;

//*******************************************************************************

method JukeboxDB.StoreSongMetadata(Song: SongMetadata): Boolean;
begin
  const DbSong = RetrieveSong(Song.Fm.FileUid);
  if DbSong <> nil then begin
    if Song <> DbSong then begin
      exit UpdateSong(Song);
    end
    else begin
      exit true;  // no insert or update needed (already up-to-date)
    end;
  end
  else begin
    // song is not in the database, insert it
    exit InsertSong(Song);
  end;
end;

//*******************************************************************************

method JukeboxDB.SqlWhereClause: String;
begin
  exit " WHERE encrypted = 0";
end;

//*******************************************************************************

method JukeboxDB.RetrieveSongs(Artist: String; Album: String): List<SongMetadata>;
begin
  var Songs := new List<SongMetadata>;
  if DbConnection <> nil then begin
    var SqlQuery := "SELECT song_uid," +
                           "file_time," +
                           "origin_file_size," +
                           "stored_file_size," +
                           "pad_char_count," +
                           "artist_name," +
                           "artist_uid," +
                           "song_name," +
                           "md5_hash," +
                           "compressed," +
                           "encrypted," +
                           "container_name," +
                           "object_name," +
                           "album_uid " +
                    "FROM song";

    SqlQuery := SqlQuery + SqlWhereClause();
    if Artist.Length > 0 then begin
      const EncodedArtist = JBUtils.EncodeValue(Artist);
      var AddedClause: String;
      if Album.Length > 0 then begin
        const EncodedAlbum = JBUtils.EncodeValue(Album);
        AddedClause := String.Format(" AND object_name LIKE '{0}--{1}%%'",
                                     EncodedArtist,
                                     EncodedAlbum);
      end
      else begin
        AddedClause := String.Format(" AND object_name LIKE '{0}--%%'",
                                     EncodedArtist);
      end;
      SqlQuery := SqlQuery + AddedClause;
    end;

    if DebugPrint then begin
      writeLn("executing query: {0}", SqlQuery);
    end;

    const Stmt = PrepareStatement(SqlQuery);
    if Stmt <> nil then begin
      try
        Songs := SongsForQueryResults(Stmt);
      finally
        sqlite3.sqlite3_finalize(Stmt);
      end;
    end;
  end;

  exit Songs;
end;

//*******************************************************************************

method JukeboxDB.SongsForArtist(ArtistName: String): List<SongMetadata>;
begin
  var Songs := new List<SongMetadata>;
  if DbConnection <> nil then begin
    var SqlQuery := "SELECT song_uid," +
                           "file_time," +
                           "origin_file size," +
                           "stored_file size," +
                           "pad_char_count," +
                           "artist_name," +
                           "artist_uid," +
                           "song_name," +
                           "md5_hash," +
                           "compressed," +
                           "encrypted," +
                           "container_name," +
                           "object_name," +
                           "album_uid " +
                    "FROM song";
    SqlQuery := SqlQuery + SqlWhereClause;
    SqlQuery := SqlQuery + " AND artist = ?";
    const Stmt = PrepareStatement(SqlQuery);
    if Stmt <> nil then begin
      try
        Songs := SongsForQueryResults(Stmt);
      finally
        sqlite3.sqlite3_finalize(Stmt);
      end;
    end;
  end;
  exit Songs;
end;

//*******************************************************************************

method JukeboxDB.ShowListings;
begin
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT artist_name, song_name " +
                     "FROM song " +
                     "ORDER BY artist_name, song_name";
    const Stmt = PrepareStatement(SqlQuery);
    if Stmt = nil then begin
      writeLn("error: unable to prepare query: " + SqlQuery);
      exit;
    end;

    try
      while sqlite3.sqlite3_step(Stmt) = sqlite3.SQLITE_ROW do begin
        const QueryResultCol1 = sqlite3.sqlite3_column_text(Stmt, 0);
        const QueryResultCol2 = sqlite3.sqlite3_column_text(Stmt, 1);
        if (QueryResultCol1 <> nil) and (QueryResultCol2 <> nil) then begin
          const Artist = MakeStringFromCString(QueryResultCol1);
          const Song = MakeStringFromCString(QueryResultCol2);
          writeLn("{0}, {1}", Artist, Song);
        end;
      end;
    finally
      sqlite3.sqlite3_finalize(Stmt);
    end;
  end
  else begin
    writeLn("error: DbConnection is nil");
  end;
end;

//*******************************************************************************

method JukeboxDB.ShowArtists;
begin
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT DISTINCT artist_name " +
                     "FROM song " +
                     "ORDER BY artist_name";
    const Stmt = PrepareStatement(SqlQuery);
    if Stmt = nil then begin
      exit;
    end;

    try
      while sqlite3.sqlite3_step(Stmt) = sqlite3.SQLITE_ROW do begin
        const QueryResultCol1 = sqlite3.sqlite3_column_text(Stmt, 0);
        if QueryResultCol1 <> nil then begin
          const Artist = MakeStringFromCString(QueryResultCol1);
          writeLn(Artist);
        end;
      end;
    finally
      sqlite3.sqlite3_finalize(Stmt);
    end;
  end;
end;

//*******************************************************************************

method JukeboxDB.ShowGenres;
begin
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT genre_name " +
                     "FROM genre " +
                     "ORDER BY genre_name";
    const Stmt = PrepareStatement(SqlQuery);
    if Stmt = nil then begin
      exit;
    end;

    try
      while sqlite3.sqlite3_step(Stmt) = sqlite3.SQLITE_ROW do begin
        const QueryResultCol1 = sqlite3.sqlite3_column_text(Stmt, 0);
        if QueryResultCol1 <> nil then begin
          const GenreName = MakeStringFromCString(QueryResultCol1);
          writeLn(GenreName);
        end;
      end;
    finally
      sqlite3.sqlite3_finalize(Stmt);
    end;
  end;
end;

//*******************************************************************************

method JukeboxDB.ShowAlbums;
begin
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT album.album_name, artist.artist_name " +
                     "FROM album, artist " +
                     "WHERE album.artist_uid = artist.artist_uid " +
                     "ORDER BY album.album_name";
    const Stmt = PrepareStatement(SqlQuery);
    if Stmt = nil then begin
      exit;
    end;

    try
      while sqlite3.sqlite3_step(Stmt) = sqlite3.SQLITE_ROW do begin
        const QueryResultCol1 = sqlite3.sqlite3_column_text(Stmt, 0);
        const QueryResultCol2 = sqlite3.sqlite3_column_text(Stmt, 1);
        if (QueryResultCol1 <> nil) and (QueryResultCol2 <> nil) then begin
          const AlbumName = MakeStringFromCString(QueryResultCol1);
          const ArtistName = MakeStringFromCString(QueryResultCol2);
          writeLn("{0} ({1})", AlbumName, ArtistName);
        end;
      end;
    finally
      sqlite3.sqlite3_finalize(Stmt);
    end;
  end;
end;

//*******************************************************************************

method JukeboxDB.ShowPlaylists;
begin
  if DbConnection <> nil then begin
    const SqlQuery = "SELECT playlist_uid, playlist_name " +
                     "FROM playlist " +
                     "ORDER BY playlist_uid";
    const Stmt = PrepareStatement(SqlQuery);
    if Stmt = nil then begin
      exit;
    end;

    try
      while sqlite3.sqlite3_step(Stmt) = sqlite3.SQLITE_ROW do begin
        const QueryResultCol1 = sqlite3.sqlite3_column_text(Stmt, 0);
        if QueryResultCol1 = nil then begin
          writeLn("Query result is nil");
          exit;
        end;
        const QueryResultCol2 = sqlite3.sqlite3_column_text(Stmt, 1);
        if QueryResultCol2 = nil then begin
          writeLn("Query result is nil");
          exit;
        end;

        const plUid = MakeStringFromCString(QueryResultCol1);
        const plName = MakeStringFromCString(QueryResultCol2);
        writeLn(plUid + " - " + plName);
      end;
    finally
      sqlite3.sqlite3_finalize(Stmt);
    end;
  end;
end;

//*******************************************************************************

method JukeboxDB.DeleteSong(SongUid: String): Boolean;
begin
  var WasDeleted := false;
  if DbConnection <> nil then begin
    if SongUid.Length > 0 then begin
      if not BeginTransaction then begin
        writeLn("error: begin transaction failed");
        exit false;
      end;

      const ArgList = new PropertyList;
      ArgList.Append(new PropertyValue(SongUid));

      const SqlStatement = "DELETE FROM song WHERE song_uid = ?";
      var RowsAffected: Int32 := 0;

      if not ExecuteUpdate(SqlStatement, out RowsAffected, ArgList) then begin
        Rollback;
        writeLn("error: unable to delete song '{0}'", SongUid);
      end
      else begin
        WasDeleted := Commit;
      end;
    end;
  end;

  exit WasDeleted;
end;

//*******************************************************************************

method JukeboxDB.MakeStringFromCString(CString: ^Byte): String;
begin
  if CString = nil then begin
    exit nil;
  end
  else begin
    {$IFDEF DARWIN}
    const Encoding = Foundation.NSStringEncoding.NSUTF8StringEncoding;
    exit new Foundation.NSString withCString(^AnsiChar(CString))
                                 encoding(Encoding);
    {$ELSE}
    exit RemObjects.Elements.System.String.FromPAnsiChar(CString as ^AnsiChar);
    {$ENDIF}
  end;
end;

//*******************************************************************************

end.