## SignalManager.gd (Autoload)
extends Node


signal updateEnabledLevel

signal levelFinished
signal beacon_reached(origin: Vector3)

## Feedback events include their source so HUDs only react to their own charger.
signal emptyEcho(charger: Node)
signal echo_recharged(charger: Node)
