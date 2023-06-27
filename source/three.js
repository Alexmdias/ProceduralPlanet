import * as THREE from 'https://cdn.skypack.dev/three@0.136';


window.addEventListener('DOMContentLoaded', async () => {

    var renderer = new THREE.WebGLRenderer();
    document.body.appendChild(renderer.domElement);
    
    //setup shaders
    const vsh = await fetch('vertex-shader.glsl');
    const fsh = await fetch('fragment-shader.glsl');
    const material = new THREE.ShaderMaterial({
      uniforms: {
        resolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
        time: { value: 0.0 },
      },
      vertexShader: await vsh.text(),
      fragmentShader: await fsh.text()
    });

    //setup scene and camera
    var scene = new THREE.Scene();
    var camera = new THREE.OrthographicCamera(0, 1, 1, 0, 0.1, 1000);
    camera.position.set(0, 0, 1);

    //add plane to draw fragment shader in
    const geometry = new THREE.PlaneGeometry(1, 1);
    const plane = new THREE.Mesh(geometry, material);
    plane.position.set(0.5, 0.5, 0);
    scene.add(plane); 
    
    //make whole window pretty with no sidebars 
    window.addEventListener('resize', () => {
      renderer.setSize(window.innerWidth, window.innerHeight);
      material.uniforms.resolution.value = new THREE.Vector2(window.innerWidth, window.innerHeight);
    }, false);
    renderer.setSize(window.innerWidth, window.innerHeight);
    material.uniforms.resolution.value = new THREE.Vector2(window.innerWidth, window.innerHeight);

    //animate with time t and render
    var previoustime = null;
    var totalTime = 0;
    function render() {
      requestAnimationFrame((t) => {
        if (previoustime === null) {
          previoustime = t;
        }
        const timeElapsed = t - previoustime;
        const timeElapsedS = timeElapsed * 0.001;
        totalTime += timeElapsedS;
        material.uniforms.time.value = totalTime;
        
        renderer.render(scene, camera);
        render();
        previoustime = t;
      });
    }

    render();
});

