using UnityEngine;

public class LogBlink : MonoBehaviour
{
    public AnimationCurve curveBlink, curveExp, curveAcceleration;
    public float duration;
    
    private float _startTime;
    private SpriteRenderer _spriteRenderer;

    private void Start()
    {
        _startTime = Time.time;
        _spriteRenderer = GetComponent<SpriteRenderer>();
        duration = Random.Range(10f, 16f);
    }

    private void Update()
    {
        var t = (Time.time - _startTime) / duration;
        if (t > 1)
            Destroy(gameObject);
        if (t > 0.5f)
        {
            var color = _spriteRenderer.color;
            color.a = 1 - curveBlink.Evaluate(curveAcceleration.Evaluate(t) * 5f) * curveExp.Evaluate(t);
            _spriteRenderer.color = color;
        }
    }
}