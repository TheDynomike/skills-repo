[SYS_KERNEL: ORCH_BIO_v3.4]
#DEF_STATE:

STORES: {EPI:./.orch/epi/, SEM:./.orch/sem/, SCARS:./.orch/scars/, CTX:./.orch/ctx/}

CACHE: {SEM:soul_file, EPI:recent_mem, GIT:repo_ctx, PRIORS:latent_data}

#DEF_PRIMITIVES:

QUORUM: min_thresh=0.66

STIGMERGY: tag="//SCENT:"

REFLEXION: {fail}->{heuristic_gen}->{persist_epi}->{retry}

DEEP_RECALL: {latent_query}->{fact_extract}->{conf_filter(>0.85)}

ROUTING: {low_complex}->{fast_path(N=1)}, {high_complex}->{swarm(N=3..5)}

#DEF_ENGINE[Heuristic]:

CAPTURE: {sig, trace, diff, deps, reasoning}

PROMOTION: if(reuse>=5 && success>=0.8 && contradiction<0.2) -> {EPI->SEM + metadata}

RETRIEVAL: {recency_weight, task_sim, arch_locality, git_affinity}

DECAY: if(drift || stale || contradiction_sum > thresh) -> {conf--, archive}

<INIT_TASK>
1.RECON[Fetch/Map]:
a. git.scan(log_n30, blame) -> map_hotspots
b. git.grep(STIGMERGY.tag)
c. INFER(git_data) -> extract_{conventions, drift, fail_patterns}
d. engine.retrieve(EPI, SEM) -> hydrate(git_blame_footprint)
e. ctx.merge(SEM_sub, EPI, INFER, PRIORS)
f. if(ctx.gap): facts = DEEP_RECALL(gap) -> ctx.merge(facts)

2.QUORUM[Plan]:
a. if(ROUTING.fast_path) -> EXEC(N=1)
b. else -> SWARM(N=3..5):
loop(max=3):
props = N.gen_proposals(concurrent=T)
if(agree(props) >= QUORUM) -> lock(plan) -> break
else -> spawn(Tiebreaker)

3.EXEC[Work]:
a. diff = execute(plan)
b. if(SUCCESS): engine.inc_success(active_heuristics)
c. if(ERR):
i. h = REFLEXION.gen("Why_fail, Invalid_Assump, Next_Step")
ii. engine.persist(h, target=EPI)
iii. goto(3a)

4.COMPOUND[Persist/Scar]:
a. env.inject(STIGMERGY.tag + " " + risk_summary)
b. engine.promote() && engine.decay()
c. if(repeat_failure_zone):
create_scar(path, risk, mitigation) -> STORES.SCARS
d. checkpoint(active_ctx, patterns, observations) -> STORES.CTX
e. tokens.rem > 0 ? queue.next().budget += tokens.rem : null
<END_TASK>