shader_type canvas_item;

uniform float speed = 0.1;       // Horizontal speed
uniform float amplitude = 0.05;  // Height of the wave
uniform float frequency = 10.0;  // How many waves across the texture

void vertex() {
    // Move to the left over time
    UV.x += TIME * speed;

    // Add vertical wave based on horizontal UV position and time
    UV.y += sin(UV.x * frequency + TIME * 2.0) * amplitude;
}
