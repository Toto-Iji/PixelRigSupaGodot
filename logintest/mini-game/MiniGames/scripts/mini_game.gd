extends Node2D

# Define the states for our minigame
enum {
	LOCKED,      # Start state, socket is locked
	UNLOCKED,    # Lever is up, ready for CPU
	CPU_PLACED,  # CPU is in the socket, ready for lock
	COMPLETED    # All done
}

var current_state = LOCKED

# We need references to our child nodes
@onready var cpu = $CPU
@onready var socket = $Socket
@onready var lever = $Lever
@onready var status_label = $StatusLabel

func _ready():
	# Set the initial instruction
	status_label.text = "Click the socket lever to unlock it."
	
	# --- THIS IS THE MOST IMPORTANT PART ---
	# We must connect the signals from our children to this script
	
	# 1. Connect the Lever's signal
	lever.connect("lever_clicked", _on_lever_clicked)
	
	# 2. Connect the CPU's signals
	cpu.connect("dropped_on_socket", _on_cpu_dropped_on_socket)
	cpu.connect("dropped_off_socket", _on_cpu_dropped_off_socket)


# This function runs when the LEVER is clicked
func _on_lever_clicked():
	match current_state:
		LOCKED:
			# --- Step 1: Unlock the lever ---
			current_state = UNLOCKED
			status_label.text = "Good. Now place the CPU in the socket."
			lever.set_unlocked() # Tell the lever to change its sprite
			
		CPU_PLACED:
			# --- Step 3: Lock the CPU in ---
			current_state = COMPLETED
			status_label.text = "Success! CPU Installed!"
			lever.set_locked() # Tell the lever to change its sprite
			
		_:
			# Clicked at the wrong time (e.g., while unlocked)
			pass


# This function runs when the CPU is dropped ON the socket
func _on_cpu_dropped_on_socket():
	match current_state:
		UNLOCKED:
			# --- Step 2: Place the CPU ---
			current_state = CPU_PLACED
			status_label.text = "Great! Click the lever to lock it down."
			# Tell the CPU to snap into place
			cpu.snap_to_socket(socket.global_position)
			
		LOCKED:
			# Tried to put the CPU in while locked
			status_label.text = "You must unlock the lever first!"
			cpu.snap_back_to_start()
			
		_:
			# Trying to drop it again? Just snap it back.
			cpu.snap_back_to_start()


# This function runs when the CPU is dropped ANYWHERE ELSE
func _on_cpu_dropped_off_socket():
	# No matter what state, if it's not on the socket, snap it back.
	cpu.snap_back_to_start()
