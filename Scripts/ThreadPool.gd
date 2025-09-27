extends Node

const thread_count = 16
var available_threads = []
var running_threads = []
var tasks_to_start = []
var tasks_to_finish = []

func _init():
	initialize_thread_pool()

# thread_info: [thread id, thread]
func initialize_thread_pool():
	running_threads.resize(thread_count)
	for i in range(0, thread_count):
		var thread_info = [i, Thread.new()]
		available_threads.append(thread_info)

# task_info: [Object to run thread on, Name of method to run]
# third argument in thread.start is userdata, the argument passed to the method to run
func queue_task(task_info):
	tasks_to_start.append(task_info)

func queue_task_finished(thread_id):
	tasks_to_finish.append(thread_id)

func try_start_task():
	if (available_threads.is_empty()): return # can't do anything else if no threads available
	if (tasks_to_start.is_empty()): return
	
	var thread_info = available_threads.pop_front() # pop_front for queue implementation
	var task_info = tasks_to_start.pop_back()

	var thread_id = thread_info[0]
	var thread = thread_info[1]
	
	var task_object = task_info[0]
	var task_name = task_info[1]
	
	thread.start(Callable(task_object, task_name).bind(thread_id))
	running_threads[thread_id] = thread_info
	#print("Running task ",task_name," on object ",task_object," and thread ",thread_id)

func try_finish_task():
	if (tasks_to_finish.is_empty()): return
	
	var thread_id = tasks_to_finish.pop_back() # pop back is- more efficient than pop_front, and order doesn't matter here
	var thread_info = running_threads[thread_id]
	var thread = thread_info[1]
	thread.wait_to_finish()
	available_threads.append(thread_info)
	running_threads[thread_id] = null
#	if (tasks_to_start.empty() and available_threads.size() == thread_count):
#		print("Finished tasks at time: ", Time.get_ticks_msec()," ms.")


func _process(_delta):
	try_start_task()
	try_finish_task()
		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
