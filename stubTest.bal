import ballerina/io;
import ballerina/mime;

public class StubTest {
    *Tests;

    public function init(string... paths) {
        self.path = "";
        self.user = ();
        self.token = ();
        self.files = [];
        foreach string path in paths {
            if self.path == "" {
                self.path = path;
            }

            string fileBase64 = "";
            do {
                fileBase64 = <string>check mime:base64Encode(check io:fileReadString(path));
            } on fail var e {
                io:println(e.message());
            }

            self.files.push({
                fileName: path,
                hash: "",
                contentb64: fileBase64
            });
        }
    }

    public function loadFiles(boolean isDir, string? suffix = (), boolean starting = true, boolean extendedLogging = false) returns RepoObject[] {
        return self.files;
    }
}

