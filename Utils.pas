﻿namespace WaterWinOxygeneCloudJukebox;

type
  Utils = public static class

  public

//*******************************************************************************

    method DirectoryExists(DirPath: String): Boolean;
    begin
      result := RemObjects.Elements.RTL.Folder(DirPath).Exists();
    end;

//*******************************************************************************

    method CreateDirectory(DirPath: String): Boolean;
    begin
      if DirectoryExists(DirPath) then
        result := false
      else
        RemObjects.Elements.RTL.Folder(DirPath).Create();
        result := true;
    end;

//*******************************************************************************

    method DeleteDirectory(DirPath: String): Boolean;
    begin
      if DirectoryExists(DirPath) then begin
        RemObjects.Elements.RTL.Folder(DirPath).Delete();
        result := true;
      end
      else begin
        result := false;
      end;
    end;

//*******************************************************************************

    method ListFilesInDirectory(DirPath: String): ImmutableList<String>;
    begin
      var theFolder := RemObjects.Elements.RTL.Folder(DirPath);
      const lenDirPath = DirPath.Length;
      var listFiles := new List<String>;
      var strippedFile: String;
      for each fileWithPath in theFolder.GetFiles() do begin
        strippedFile := fileWithPath.Substring(lenDirPath);
        if strippedFile[0] = RemObjects.Elements.RTL.Path.DirectorySeparatorChar then begin
          strippedFile := strippedFile.Substring(1);
        end;
        listFiles.Add(strippedFile);
      end;
      result := listFiles;
    end;

//*******************************************************************************

    method ListDirsInDirectory(DirPath: String): ImmutableList<String>;
    begin
      const lenDirPath = DirPath.Length;
      var listSubdirs := new List<String>;
      var strippedDir: String;
      for each subDirWithPath in RemObjects.Elements.RTL.Folder(DirPath).GetSubfolders() do begin
         strippedDir := subDirWithPath.Substring(lenDirPath);
         if strippedDir[0] = RemObjects.Elements.RTL.Path.DirectorySeparatorChar then begin
           strippedDir := strippedDir.Substring(1);
         end;
         listSubdirs.Add(strippedDir);
      end;
      result := listSubdirs;
    end;

//*******************************************************************************

    method DeleteFilesInDirectory(DirPath: String);
    //var
    //  aFile: RemObjects.Elements.RTL.File;
    begin
      var aFolder := RemObjects.Elements.RTL.Folder(DirPath);
      for each FileName in aFolder.GetFiles() do begin
        var aFile := RemObjects.Elements.RTL.File(PathJoin(DirPath, FileName));
        aFile.Delete();
      end;
    end;

//*******************************************************************************

    method PathJoin(DirPath: String; FileName: String): String;
    begin
      const DirPathSeparator = RemObjects.Elements.RTL.Path.DirectorySeparatorChar;
      if not DirPath.EndsWith(DirPathSeparator) then begin
        result := DirPath + DirPathSeparator + FileName;
      end
      else begin
        result := DirPath + FileName;
      end;
      //result := RemObjects.Elements.RTL.Path.Combine(DirPath, FileName);
    end;

//*******************************************************************************

    method PathSplitExt(FilePath: String): tuple of (String, String);
    begin
      // splitext("bar") -> ("bar", "")
      // splitext("foo.bar.exe") -> ("foo.bar", ".exe")
      // splitext("/foo/bar.exe") -> ("/foo/bar", ".exe")
      // splitext(".cshrc") -> (".cshrc", "")
      // splitext("/foo/....jpg") -> ("/foo/....jpg", "")

      var Root := "";
      var Ext := "";

      if FilePath.Length > 0 then begin
        const PosLastDot = FilePath.LastIndexOf('.');
        if PosLastDot = -1 then begin
          // no '.' exists in path (i.e., "bar")
          Root := FilePath;
        end
        else begin
          // is the last '.' the first character? (i.e., ".cshrc")
          if PosLastDot = 0 then begin
            Root := FilePath;
          end
          else begin
            const preceding = FilePath[PosLastDot-1];
            // is the preceding char also a '.'? (i.e., "/foo/....jpg")
            if preceding = '.' then begin
              Root := FilePath;
            end
            else begin
              // splitext("foo.bar.exe") -> ("foo.bar", ".exe")
              // splitext("/foo/bar.exe") -> ("/foo/bar", ".exe")
              Root := FilePath.Substring(0, PosLastDot);
              Ext := FilePath.Substring(PosLastDot);
            end;
          end;
        end;
      end;

      result := (Root, Ext);
    end;

//*******************************************************************************

    method FileExists(FilePath: String): Boolean;
    begin
      result := RemObjects.Elements.RTL.File(FilePath).Exists();
    end;

//*******************************************************************************

    method DeleteFile(FilePath: String): Boolean;
    begin
      if FileExists(FilePath) then begin
        RemObjects.Elements.RTL.File(FilePath).Delete();
        result := true;
      end
      else begin
        result := false;
      end;
    end;

//*******************************************************************************

    method RenameFile(OldPath: String; NewPath: String): Boolean;
    begin
      if FileExists(OldPath) then begin
        var NewFile := RemObjects.Elements.RTL.File(OldPath).Rename(NewPath);
        result := NewFile.Exists();
      end
      else begin
        result := false;
      end;
    end;

//*******************************************************************************

    method FileWriteAllBytes(FilePath: String; Contents: array of Byte): Boolean;
    begin
      RemObjects.Elements.RTL.File.WriteBytes(FilePath, Contents);
      result := true;
    end;

//*******************************************************************************

    method FileReadAllBytes(FilePath: String): array of Byte;
    begin
      result := RemObjects.Elements.RTL.File.ReadBytes(FilePath);
    end;

//*******************************************************************************

    method FileWriteAllText(FilePath: String; Contents: String): Boolean;
    begin
      RemObjects.Elements.RTL.File.WriteText(FilePath, Contents,
                                             RemObjects.Elements.RTL.Encoding.UTF8);
      result := true;
    end;

//*******************************************************************************

    method FileReadAllText(FilePath: String): String;
    begin
      result := RemObjects.Elements.RTL.File.ReadText(FilePath);
    end;

//*******************************************************************************

    method FileReadTextLines(FilePath: String): ImmutableList<String>;
    begin
      result := RemObjects.Elements.RTL.File.ReadLines(FilePath,
                                                       RemObjects.Elements.RTL.Encoding.UTF8);
    end;

//*******************************************************************************

    method Md5ForFile(FilePath: String): String;
    begin
      //TODO: implement md5ForFile
      result := '';
    end;

//*******************************************************************************

    method GetPid(): Integer;
    begin
      result := RemObjects.Elements.System.Process.CurrentProcessId();
    end;

//*******************************************************************************

    method GetFileSize(FilePath: String): Int64;
    begin
      result := RemObjects.Elements.RTL.File(FilePath).Size;
    end;

//*******************************************************************************

    method GetCurrentDirectory: String;
    begin
      result := RemObjects.Elements.RTL.Environment.CurrentDirectory;
    end;

//*******************************************************************************

  end;

end.