extends Node2D
## 메인 장면(프로토타입 1): 쿼터뷰 필드에 주인공을 세우고 카메라 범위를 정한다.
## 조이스틱(HUD)은 입력 액션을 통해 주인공과 이어지므로 따로 연결하지 않는다.

@onready var _field: Field = $Field
@onready var _player: Player = $Field/Objects/Player


func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.SEA)
	_player.set_camera_limits(_field.bounds().grow(GameConfig.CAMERA_LIMIT_MARGIN))
	_player.place_at(_field.spawn_position())
