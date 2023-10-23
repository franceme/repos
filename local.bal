import ballerina/file;
import ballerina/io;
import ballerina/log;
import frantzme/stringz as str;

public class LocalTests {
    *Tests;

    public function init(string path, string? user, string? token) {
        self.path = path;
        self.user = user;
        self.token = token;
        self.files = [];
    }
    public function loadFiles(boolean isDir, string? suffix = (), boolean starting = true, boolean extendedLogging = false) returns RepoObject[] {
        self.files = self.iterate(self.user ?: "", self.path,
            isDir = isDir, suffix = suffix, starting = starting, extendedLogging = extendedLogging
        );
        return self.files;
    }

    function iterate(string user, string repo, string? file = (), boolean isDir = false, boolean dirContinuing = true, string? suffix = (), string? lastHash = (), boolean starting = false, boolean extendedLogging = false) returns RepoObject[] {
        RepoObject[] output = [];
        boolean|error repoExists = file:test(repo, file:EXISTS);
        if repoExists is error || !repoExists {
            return output;
        }

        if starting {
            log:printDebug({message: "Loading"}.toJsonString());
        }
        if extendedLogging {
            log:printDebug({message: "Checking Path", path: repo}.toJsonString());
        }

        if isDir == true {
            file:MetaData[]|error directoryContent = file:readDir(repo);

            if directoryContent is error {
                return output;
            }

            //https://github.com/ballerina-platform/ballerina-lang/issues/1107
            //https://ballerina.io/learn/by-example/filepaths/
            foreach file:MetaData dirObject in directoryContent {
                string|file:Error dirObjectName = file:basename(dirObject.absPath);
                if !(dirObjectName is error) && (
                    (suffix == () || dirObjectName.endsWith(suffix))
                ) {
                    RepoObject[] fileResults = self.iterate(user, dirObject.absPath, null, dirObject.dir, dirContinuing, null, lastHash = null, extendedLogging = true);
                    foreach RepoObject fileResult in fileResults {
                        output.push(fileResult);
                    }
                }
            }

        } else {
            file:MetaData|error res = file:getMetaData(repo);

            if res is error {
                return output;
            }

            string|error fileContents = io:fileReadString(res.absPath);

            if fileContents is error {
                return output;
            }

            RepoObject temp = {
                fileName: res.absPath,
                hash: "",
                contentb64: str:stringToBase64(fileContents)
            };
            output.push(temp);

        }
        if starting {
            log:printDebug({message: "Finished Loading"}.toJsonString());
        }
        return output;
    }

};
