Shader "Unlit/NewUnlitShader" {
    Properties {
        _Color ("Main Color", Color) = (1, 0., 0., 1)
    }
    SubShader {
        Pass {
            Material {
                Diffuse [_Color]
            }
            Lighting On
        }
    }
}