using UnityEngine;

public class CircleScript : MonoBehaviour
{
    [Range(1, 100)] public const float Velocity = 14.0f;
    [Range(0.1f, 1)] public float duration = 0.6f;

    private SpriteRenderer _spriteRenderer;
    private float _elapsed;

    private void Start()
    {
        _spriteRenderer=GetComponent<SpriteRenderer>();
    }

    private void Update()
    {
        _elapsed += Time.deltaTime;
        var localScale = transform.localScale;
        localScale = new Vector2(localScale.x,
            localScale.y - localScale.y * _elapsed / (duration * Random.Range(60, 100)));
        transform.localScale = localScale;
        var color = _spriteRenderer.color;
        color.a = 1 - _elapsed / duration;
        _spriteRenderer.color = color;
        if (_elapsed > duration)
            Destroy(gameObject);
    }
}