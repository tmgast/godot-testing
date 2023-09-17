extends CharacterBody3D

## Walk speed
@export var base_speed = 5
## Dash speed
@export var sprint_speed = 30
## Time in seconds player will dash
@export var dash_time = 0.2
## Number of air jumps
@export var jumpCount = 4
## Jump strength
@export var jump_velocity = 7
@export var sensitivity = 0.1
@export var accel = 10
var bDashing = false
var currentJump = 0
var speed = base_speed
var sprinting = false
var bJustDashed = false
var camera_fov_extents = [80.0, 90.0] #index 0 is normal, index 1 is sprinting

var dashCooldown = 0.0
var direction = Vector3(0.0,0.0,0.0)
var groundAccel = 10
var airAccel = 20


@onready var parts = {
  "head": $head,
  "camera": $head/camera,
  "camera_animation": $head/camera/camera_animation
}
@onready var world = get_parent()

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
  world.pause.connect(_on_pause)
  world.unpause.connect(_on_unpause)
  
  parts.camera.current = true

func _process(delta):
  if dashCooldown > 0.0:
    dashCooldown -= delta
    if dashCooldown <= 0.0:
      bJustDashed = true
      sprinting = false
      speed = base_speed
      parts.camera.fov = lerp(parts.camera.fov, camera_fov_extents[0], 10*delta)

  if Input.is_action_just_pressed("move_sprint"):
    sprinting = true
    dashCooldown = dash_time
    speed = sprint_speed
    parts.camera.fov = lerp(parts.camera.fov, camera_fov_extents[1], 10*delta)

func _physics_process(delta):
  if not is_on_floor():
    accel = airAccel
    velocity.y -= gravity * delta
  else:
    accel = groundAccel
    currentJump = 0

  if Input.is_action_just_pressed("move_jump") and (is_on_floor() or currentJump < jumpCount):
    currentJump += 1
    velocity.y = jump_velocity

  var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
  if !sprinting:
    direction = input_dir.normalized().rotated(-parts.head.rotation.y)
    direction = Vector3(direction.x, 0, direction.y)
  if is_on_floor() or sprinting or bJustDashed: #don't lerp y movement
    velocity.x = lerp(velocity.x, 0.0 if bJustDashed else (direction.x * speed), accel * delta)
    velocity.z = lerp(velocity.z, 0.0 if bJustDashed else (direction.z * speed), accel * delta)
    
  if bJustDashed:
    bJustDashed = false
  
  #bob head
  if input_dir and is_on_floor():
    parts.camera_animation.play("head_bob", 0.5)
  else:
    parts.camera_animation.play("reset", 0.5)

  move_and_slide()

func _input(event):
  if event is InputEventMouseMotion:
    if !world.paused:
      parts.head.rotation_degrees.y -= event.relative.x * sensitivity
      parts.head.rotation_degrees.x -= event.relative.y * sensitivity
      parts.head.rotation.x = clamp(parts.head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _on_pause():
  pass

func _on_unpause():
  pass
