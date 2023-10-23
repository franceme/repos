public type RepoObject record {|
    string fileName;
    string hash;
    string contentb64;
|};

public type Tests object {
    # https://ballerina.io/learn/language-basics/#define-classes
    string path;
    RepoObject[] files;
    string? token;
    string? user;

    public function loadFiles(boolean isDir, string? suffix = (), boolean starting = true, boolean extendedLogging = false) returns RepoObject[];
};

public function load(string level, string path, string? user = (), string? token = ()) returns Tests? {
    if level == "local" {
        return new LocalTests(path, user, token);
    } else if level == "remote" {
        return new RemoteTests(path, user, token);
    } else if level == "stub" {
        return new StubTest(path);
    }
    return ();
}
