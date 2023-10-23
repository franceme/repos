import ballerina/io;
import ballerina/http;

public class RemoteTests {
    *Tests;

    public function init(string path, string? user, string? token) {
        self.path = path;
        self.user = user;
        self.token = token;
        self.files = [];
    }

    function headers() returns map<string> {
        return {
            "Authorization": "Bearer " + (self.token ?: ""),
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28"
        };
    }

    function request(string path) returns json {
        http:Client|http:ClientError httpEP = new ("https://api.github.com");
        if httpEP is error {
            return {};
        }
        //https://stackoverflow.com/questions/66356627/ballerina-using-json-response-from-rest-api
        json|error res = httpEP->get(path, headers = self.headers());
        if res is error {
            return {};
        } else {
            return res;
        }
    }

    function requests(string path) returns json[] {
        http:Client|http:ClientError httpEP = new ("https://api.github.com");
        if httpEP is error {
            return [];
        }
        //https://stackoverflow.com/questions/66356627/ballerina-using-json-response-from-rest-api
        json[]|error res = httpEP->get(path, headers = self.headers());
        if res is error {
            return [];
        } else {
            return res;
        }
    }

    public function loadFiles(boolean isDir, string? suffix = (), boolean starting = true, boolean extendedLogging = false) returns RepoObject[] {
        self.files = self.iterate(self.user ?: "", self.path,
            isDir = isDir, suffix = suffix, starting = starting, extendedLogging = extendedLogging
        );
        return self.files;
    }

    function iterate(string user, string repo, string? file = (), boolean isDir = false, boolean dirContinuing = true, string? suffix = (), string? lastHash = (), boolean starting = false, boolean extendedLogging = false) returns RepoObject[] {
        RepoObject[] output = [];
        if starting {
            io:print({message: "Loading"}.toJsonString());
        }
        if extendedLogging {
            io:print(".");
        }
        if file == () || isDir == true {
            json[] directoryContent = self.requests("/repos/" + user + "/" + repo + "/contents/" + (file == () ? "" : file));
            if directoryContent.length() == 1000 && lastHash != () {
                //Since my folder has more than 1,000 files within, need to use git trees
                //https://docs.github.com/en/rest/git/trees?apiVersion=2022-11-28#get-a-tree
                json largeTree = <json>self.request("/repos/" + user + "/" + repo + "/git/trees/" + lastHash + "?recursive=1");
                json[]|error treeVines = <json[]|error>largeTree.tree;

                if treeVines is error {
                    return output;
                }

                foreach json dirObject in treeVines {
                    json|error currentHash = dirObject.sha;
                    json|error currentPathing = dirObject.path;
                    if !(currentHash is error) && !(currentPathing is error) {
                        RepoObject[] fileResults = self.iterate(user, repo, (file == () ? "" : file + "/") + <string>currentPathing, dirObject.'type == "tree", dirContinuing, null, lastHash = <string>currentHash);
                        foreach RepoObject fileResult in fileResults {
                            output.push(fileResult);
                        }
                    }
                }
                directoryContent = [];
            }

            //https://github.com/ballerina-platform/ballerina-lang/issues/1107
            foreach json dirObject in directoryContent {
                json|error dirObjectName = <json|error>dirObject.name;
                json|error currentHash = dirObject.sha;
                if !(currentHash is error) && !(dirObjectName is error) && (
                    (suffix == () || (<string>dirObjectName).endsWith(suffix))
                ) {
                    RepoObject[] fileResults = self.iterate(user, repo, (file == () ? "" : file + "/") + (<string>dirObjectName), dirObject.'type == "dir", dirContinuing, null, lastHash = <string>currentHash);
                    foreach RepoObject fileResult in fileResults {
                        output.push(fileResult);
                    }
                }
            }

        } else {
            json|error res = self.request("/repos/" + user + "/" + repo + "/contents/" + file);

            if res is error {
            }
            else {
                json|error subSha = res.sha;
                if !(subSha is error) {
                    json response = <json>self.request("/repos/" + user + "/" + repo + "/git/blobs/" + (<string>subSha));

                    json|error currentContent = response.content;
                    if !(currentContent is error) {
                        RepoObject temp = {
                            fileName: file,
                            hash: <string>subSha,
                            contentb64: <string>currentContent
                        };
                        output.push(temp);
                    }
                }
            }
        }
        if starting {
            io:print({message: "Finished Loading"}.toJsonString());
        }
        return output;
    }

};
