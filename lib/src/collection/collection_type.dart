enum CollectionType {
  unknown,
  document,
  edge,
}

CollectionType parseCollectionType(int type) {
  switch (type) {
    case 0:
      return CollectionType.unknown;
    case 2:
      return CollectionType.document;
    case 3:
      return CollectionType.edge;
    default:
      return CollectionType.unknown;
  }
}
