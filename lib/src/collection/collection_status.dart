enum CollectionStatus {
  unknown,
  unloaded,
  loaded,
  unloading,
  deleted,
  loading,
}

CollectionStatus parseCollectionStatus(int status) {
  switch (status) {
    case 0:
      return CollectionStatus.unknown;
    case 1:
      return CollectionStatus.unknown;
    case 2:
      return CollectionStatus.unloaded;
    case 3:
      return CollectionStatus.loaded;
    case 4:
      return CollectionStatus.unloading;
    case 5:
      return CollectionStatus.deleted;
    case 6:
      return CollectionStatus.loading;
    default:
      return CollectionStatus.unknown;
  }
}
