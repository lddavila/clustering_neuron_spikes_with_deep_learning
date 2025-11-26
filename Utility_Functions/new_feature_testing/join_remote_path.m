function full_path = join_remote_path(base, rel)
    base = char(base);
    rel  = char(rel);
    base = strrep(base, '\', '/');
    rel  = strrep(rel,  '\', '/');

    if endsWith(base, '/')
        full_path = [base rel];
    else
        full_path = [base '/' rel];
    end
end