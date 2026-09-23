function worker_count = start_pipeline_workers(requested_workers)
%START_PIPELINE_WORKERS Start one pool that can be reused by the pipeline.

worker_count = 0;
if requested_workers == 0 || ...
        ~license("test", "Distrib_Computing_Toolbox") || ...
        ~exist("parpool", "file")
    fprintf("using a normal serial loop\n");
    return
end

current_pool = gcp("nocreate");
if isempty(current_pool)
    try
        fprintf("starting a pool with %d workers...\n", requested_workers);
        current_pool = parpool("Processes", requested_workers);
    catch pool_error
        fprintf("the parallel pool did not start: %s\n", pool_error.message);
        fprintf("using a normal serial loop\n");
        return
    end
end

worker_count = min(requested_workers, current_pool.NumWorkers);
fprintf("using %d parallel workers\n", worker_count);
end
