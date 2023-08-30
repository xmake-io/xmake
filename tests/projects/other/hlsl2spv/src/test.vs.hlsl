struct VS_INPUT
{
    float2 pos : POSITION;
    float3 color : COLOR0;
};

struct VS_OUTPUT
{
    float4 pos : SV_POSITION;
    float3 color : COLOR0;
};

VS_OUTPUT main(VS_INPUT input)
{
    VS_OUTPUT output;
    output.pos = float4(input.pos, 0.0, 1.0);
    output.color = input.color;

    return output;
}
