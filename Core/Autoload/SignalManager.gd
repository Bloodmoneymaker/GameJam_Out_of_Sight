## SignalManager.gd (Autoload)
extends Node


signal updateEnabledLevel

signal levelFinished

## Feedback events include their source so HUDs only react to their own charger.
signal emptyEcho(charger: Node)
signal echo_recharged(charger: Node)
