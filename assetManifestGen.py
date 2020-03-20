import os

# Set asset directory for the project.
assetdir = os.getcwd() + "/android/assets"

# Write to a new file.
with open(assetdir + "/assetManifest.txt", "w") as f:
    # For each directory in assetdir,
    for rootDir, childDirs, files in os.walk(assetdir):
        # Split to get the trailing directory, and replace the path separator.
        rootDirStr = rootDir.split(assetdir)[1].replace("\\", "/") + "/"
        for file in files:
            # Write the file path for each file, excluding the first character /.
            f.write(rootDirStr[1:] + file + "\n")
