from argparse import ArgumentError
from operator import contains
import os
import sys
import re

EXTENDS_START = "--!extends"
EXTENDS_END = "--/extends"

def parseSubclass(classPath: str):
    className = os.path.basename(classPath).split(".")[0]  # Can parse absolute path
    classFile = readToString(classPath)
    superName = re.search(f"{EXTENDS_START} (.+)", classFile).group(1)
    superFile = readToString(f"{superName}.tl")  # TODO: look at require()

    superRecord = re.search(f"record {superName}(.|\n)*?(\nend)", superFile).group()
    superRecordLines = re.split("\n\s*", superRecord)

    filtered = filter(
        lambda line:
        not line.startswith("--")
        and not line.startswith("new:")
        and not line.startswith("instantiate:")
        and not line.startswith("metamethod "),
        superRecordLines[1:-1])  # Excludes record/end lines
    filteredList = list(filtered)

    subbedClassNames = map(lambda method: re.sub(f"\\b{superName}\\b", className, method), filteredList)
    
    appendSuper = "" if (superName == "Class") else f", {superName}"
    toWrite = [f"instantiate: function({className}{appendSuper}): {className}"]
    toWrite.extend(list(subbedClassNames))

    indent = re.search(f"\n(.*){EXTENDS_START}", classFile).group(1)
    indentToWrite = list(map(lambda line: indent + line, toWrite))

    writeString = "\n".join(indentToWrite) + "\n"
    writeData = re.sub(
        pattern = f"({EXTENDS_START}.+\n)(.|\n)*?(.*{EXTENDS_END})",
        repl = f"\\1{writeString}\\3",
        string = classFile
    )
    writeToFile(classPath, writeData)

def readToString(path: str) -> str:
    with open(path) as file:
        s = file.read()
    return s

def writeToFile(path: str, data: str):
    with open(path, "w") as file:
        file.write(data)


# Parse command line args

if len(sys.argv) != 2:
    s = f"Give the filename of the subclass annotated with '{EXTENDS_START}'."
    raise ArgumentError(None, s)

classPath = sys.argv[1]

parseSubclass(classPath)

