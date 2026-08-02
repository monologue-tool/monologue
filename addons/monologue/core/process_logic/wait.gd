class_name MonologueWaitLogic extends MonologueProcessLogic


func enter(ctx: MonologueContext, node: Dictionary, _data: Dictionary = {}) -> MonologueProcessResult:
	await ctx.timeline.create_timer(node.get("Time")).timeout
	
	return MonologueProcessResult.continue_process(node.get("NextID"))
