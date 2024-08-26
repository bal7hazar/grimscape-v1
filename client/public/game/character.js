import * as THREE from '../node_modules/three/build/three.module.js';
import { createFightInfoText, createStaticText } from '../utils/text.js';
import { worldToScreenPosition } from '../utils/utils.js';

export function addCharacter(scene, object, maxHp, position, rotation) {
    object.animationMixer = new THREE.AnimationMixer(object)
    object.animations = {
        idle: object.animationMixer.clipAction(object.animations[0])
    }
    object.animations.idle.name = 'idle'
    object.animations.idle.play()
    object.animationMixer.addEventListener( 'finished', function( e	) {
        if (e.action.name !== 'idle') {
            object.animations.idle.play()
        }
    });

    object.traverse(function (node) {
        if (node.isMesh) {
            node.castShadow = true; // Cast shadow
            node.receiveShadow = true; // Receive shadow
        }
    });
    object.position.set(position[0], position[1], position[2])
    object.rotation.set(rotation[0], rotation[1], rotation[2])
    object.scale.set(0.5,0.5,0.5)
    scene.add(object)
    const clock = new THREE.Clock()
    scene.tickCallbacks.push(() => {
        object.animationMixer.update(clock.getDelta())
    })

    object.maxHp = maxHp
    object.hp = maxHp

    let textHP = createStaticText(scene, `${object.hp}/${object.maxHp}`, [position[0], 1.2, position[2]])
    object.textHP = textHP

    object.attack = function() {
        if (object.animations.punch) {
            object.animations.idle.stop()
            object.animations.punch.reset()
            object.animations.punch.play()
        }
    }

    object.hit = function(damage) {
        if (damage <= 0) {
            return
        }
        if (object.hp <= 0) {
            console.error("already dead")
            return;   
        }
        object.hp -= damage
        if (object.hp <= 0) {
            object.hp = 0
        }
        if (object.animations.take_punch) {
            object.animations.idle.stop()
            object.animations.take_punch.reset()
            object.animations.take_punch.play()
        }
        textHP.updateText(`${object.hp}/${object.maxHp}`)
        createFightInfoText(scene, `-${damage} HP`, [position[0], 1.5, position[2]])
    }

    const loader = new THREE.ImageBitmapLoader();
    loader.setOptions( { imageOrientation: 'flipY' } );
    object.prepare = function(spellId) {
        object.currentSpell = spellId
        const name = spellId == 2 ? "punch" : "stun";
        loader.load(
            `assets/icons/${name}.png`,
            function (imageBitmap) {
                const texture = new THREE.CanvasTexture(imageBitmap);
                const material = new THREE.MeshBasicMaterial({ map: texture });
                const geometry = new THREE.PlaneGeometry(0.1, 0.1);
                const quad = new THREE.Mesh(geometry, material);
                scene.add(quad);
                quad.layers.set(2);
                quad.refresh = function() {
                    const screenPos = worldToScreenPosition(scene, [position[0], 1.5, position[2]])
                    screenPos[0] -= 0.1
                    quad.position.set(...screenPos)    
                }
                scene.tickCallbacks.push(() => {
                    quad.refresh()
                })
            
            },
            undefined,
            function (err) {
                console.log( 'An error happened', err ); 
            }
        );
    }

    return object
}