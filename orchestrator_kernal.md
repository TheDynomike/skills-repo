[SYS_KERNEL: ORCH_BIO_v3.2]
#DEF_STATE:{SEM:soul_file_cache, EPI:recent_mem.md, GIT:repo_ctx, PRIORS:latent_training_data}
#DEF_PRIMITIVES:

QUORUM: min_thresh=0.66
STIGMERGY: tag="//SCENT:"
REFLEXION: {fail}->{heuristic}->{retry}
ROUTING: {trivial}->{fast_path}, {complex}->{swarm}
DEEP_RECALL: {query_latent_space}->{extract_facts}->{confidence_filter(>0.85)}

<INIT_TASK>
1.RECON[Fetch, Synthesize, Map]:
   a. git.scan(log_n30, blame) -> map_temporal_hotspots
   b. git.grep(STIGMERGY.tag)
   c. INFER(git_data) -> extract_{conventions, architecture_drift}
   d. soul_file.hydrate(git_blame_footprint) -> selectively load SEM chunks
   e. ctx.merge(SEM_subset, EPI, INFER)
   f. if(ctx.knowledge_gap == TRUE || new_dependency_detected):
      i. facts = DEEP_RECALL.gen("Dump offline training priors/API docs for: {gap}")
      ii. if(facts.confidence >= 0.85) -> ctx.merge(facts)
2.QUORUM[Evaluate & Plan]:
   a. complexity = calc_complexity(ctx)
   b. if(complexity == LOW) -> FAST_PATH:
      i. N = 1 (Direct Execution Plan)
   c. else -> SWARM:
      i. N = 3..5 (Local Parallel Proposals)
      ii. loop(max=3):
         - props = N.generate_proposals(concurrent=True)
         - if(agree(props) >= QUORUM) -> lock(plan) -> break
         - else -> spawn(Tiebreaker_Node)
3.EXEC[Work]:
   a. diff = execute(plan)
   b. validate(diff)
   c. if(ERR):
      i. h = REFLEXION.gen("Why failed? Limits? Next step?")
      ii. EPI.append(h)
      iii. goto(3a)
4.COMPOUND[Persist & Prune]:
   a. env.inject(STIGMERGY.tag + " " + risk_summary)
   b. EPI.update(success_heuristics)
   c. if(EPI.rule_count(x) >= 3):  // Note: Adjusted to 3 for local speed
      i. soul_file.cache_metadata(x, target_dir) -> promote to SEM
      ii. EPI.prune(x)
<END_TASK>
