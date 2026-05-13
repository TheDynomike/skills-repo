[SYS_KERNEL: ORCH_BIO_v3.9]
#DEF_STATE:

STORES: {EPI:./.orch/epi/, SEM:./.orch/sem/, CTX:./.orch/ctx/}

CACHE: {SEM:soul_file.md, EPI:recent_mem.md, GIT:repo_ctx, PRIORS:latent_data}

#DEF_OUTPUT_SCHEMA:

EMIT_STRICT_XML:  ->  ->  -> 

#DEF_PRIMITIVES:

BOOT: if(!dir(STORES)) -> fs.mkdir_p(STORES) && fs.touch(CACHE.files)

QUORUM: min_thresh=0.66

STIGMERGY: marker="SCENT:", format=lang.comment_syntax(file) + marker

REFLEXION: {fail}->{heuristic_gen}->{persist_epi}->{retry}

DEEP_RECALL: {latent_query}->{fact_extract}->{conf_filter(>0.85)}

ROUTING: {low_complex}->{fast_path(N=1)}, {high_complex}->{swarm(N=3..5)}

#DEF_ENGINE[Heuristic]:

CAPTURE: {sig, trace, diff, deps, reasoning}

PROMOTION: if(reuse>=5 && success>=0.8 && contradiction<0.2) -> {EPI->SEM + metadata}

RETRIEVAL: {recency_weight, task_sim, arch_locality, git_affinity}

DECAY: if(drift || stale || contradiction_sum > thresh) -> {conf--, archive}

<INIT_TASK>
0.BOOT: Apply BOOT. Ensure .orch/ hierarchy exists.

1.RECON[Fetch/Map] -> emit :
a. git.scan(log_n30, blame) -> map_hotspots
b. git.grep(STIGMERGY.marker)
c. INFER(git_data) -> extract_{conventions, drift, fail_patterns}
d. engine.retrieve(EPI, SEM) -> hydrate(git_blame_footprint)
e. ctx.merge(SEM_sub, EPI, INFER, PRIORS)
f. if(ctx.gap): facts = DEEP_RECALL(gap) -> ctx.merge(facts)

2.QUORUM[Plan] -> emit :
a. if(ROUTING.fast_path) -> EXEC(N=1)
b. else -> SWARM(N=3..5):
loop(max=3):
props = N.gen_proposals(concurrent=T)
if(agree(props) >= QUORUM) -> lock(plan) -> break
else -> spawn(Tiebreaker)

3.EXEC[Work] -> emit :
a. diff = execute(plan)
b. if(SUCCESS): engine.inc_success(active_heuristics)
c. if(ERR):
i. h = REFLEXION.gen("Why_fail, Invalid_Assump, Next_Step")
ii. engine.persist(h, target=EPI)
iii. goto(3a)

4.COMPOUND[Persist] -> emit :
a. env.inject(STIGMERGY.format + " " + risk_summary)
b. engine.promote() && engine.decay()
c. checkpoint(active_ctx, patterns, observations) -> STORES.CTX
d. tokens.rem > 0 ? queue.next().budget += tokens.rem : null
<END_TASK>
