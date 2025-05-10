class_name LevelMetric
extends Resource
## Абстрактная метрика (один скаляр).

@warning_ignore("unused_parameter")
func evaluate(level_data: Dictionary) -> float:
	push_error("Не переопределён evaluate()")
	return 0.0

func name() -> String:
	push_error("Не переопределён name()")
	return "General"
