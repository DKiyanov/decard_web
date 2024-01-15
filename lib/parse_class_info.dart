class ParseWebPackUpload {
  static const String className = 'UploadWebFile';

  static const String userID    = 'UserID';
  static const String fileName  = 'FileName';
  static const String size      = 'Size';
  static const String content   = 'Content';
}

class ParseWebPackHead {
  static const String className    = 'DecardFileHead';

  static const String packId       = 'packID';
  static const String content      = 'Content';
  static const String fileName     = 'FileName';
  static const String fileSize     = 'FileSize';
  static const String createdAt    = 'createdAt';
  static const String publicationMoment = 'PublicationMoment';
  static const String starsCount   = 'StarsCount';
  static const String userID       = 'UserID';
}

class ParseWebPackSubFile {
  static const String className    = 'DecardFileSub';

  static const String packId       = 'packID';
  static const String file         = 'file';
  static const String path         = 'path';
  static const String isText       = 'isText';
  static const String textContent  = 'textContent';
}

class ParseWebPackUserFiles {
  static const String className    = 'DecardUserFiles';

  static const String userID       = 'UserID';
  static const String packId       = 'packID';
}

class ParseChild {
  static const String className  = 'Child';

  static const String userID     = 'UserID';
  static const String name       = 'Name';
}

class ParseDevice {
  static const String className  = 'Device';

  static const String userID     = 'UserID';
  static const String childID    = 'ChildID';
  static const String name       = 'Name';
  static const String deviceOSID = 'DeviceOSID';
}

class ParseWebChildSource {
  static const String className   = 'DecardFile';
  static const String userID      = 'UserID';
  static const String path        = 'Path';
  static const String fileName    = 'FileName';
  static const String size        = 'Size';
  static const String content     = 'Content';

  static const String textContent = 'TextContent';
  static const String addInfo     = 'AddInfo';
  static const String sourceType  = 'SourceType';

  static const String sourceTypePack      = 'pack';
  static const String sourceTypeRegulator = 'regulator';
}