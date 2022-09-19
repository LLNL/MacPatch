def containsPathFromList(path, Paths):
	for x in Paths:
		if x in path:
			return True

	return False