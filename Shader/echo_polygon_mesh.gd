@tool
extends MeshInstance3D
## Give each real triangle its own barycentric coordinates for the echo mask.
## Positions and triangle topology stay identical; collision stays unchanged.

func _ready() -> void:
	if mesh == null:
		return
	var outlined_mesh := ArrayMesh.new()
	for surface in range(mesh.get_surface_count()):
		if mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			push_warning("Echo polygon edges require a triangle mesh.")
			return
		var surface_tool := SurfaceTool.new()
		surface_tool.create_from(mesh, surface)
		surface_tool.deindex()
		var arrays := surface_tool.commit_to_arrays()
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var coordinates := PackedColorArray()
		coordinates.resize(vertices.size())
		for vertex in range(vertices.size()):
			match vertex % 3:
				0: coordinates[vertex] = Color(1, 0, 0, 1)
				1: coordinates[vertex] = Color(0, 1, 0, 1)
				2: coordinates[vertex] = Color(0, 0, 1, 1)
		arrays[Mesh.ARRAY_COLOR] = coordinates
		outlined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		outlined_mesh.surface_set_material(surface, mesh.surface_get_material(surface))
	mesh = outlined_mesh
