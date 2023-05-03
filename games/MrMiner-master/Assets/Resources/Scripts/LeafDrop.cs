using UnityEngine;

public class LeafDrop : MonoBehaviour
{
    public AnimationCurve moveCurveX, moveCurveY, rotateCurveZ;
    public float finalPosY = 1f;
    public Vector2 durationRange;
    [Range(0.001f, 1f)] public float speed;

    private Vector3 _startPoint;
    private PolygonCollider2D _treeCollider;
    private float _timeStart;
    private float _duration;
    private SpriteRenderer _spriteRenderer;
    private Camera _camera;

    private void Start()
    {
        _camera = GameObject.FindGameObjectWithTag("MainCamera").GetComponent<Camera>();
        
        _treeCollider = GameObject.Find("LeafSpawnZone").GetComponent<PolygonCollider2D>();
        _startPoint = utilies.RandomPointInCollider(_treeCollider,_camera);
        transform.position = _startPoint;

        var keyframes = rotateCurveZ.keys;
        keyframes[^1].value = Random.Range(-1f, 1f);
        rotateCurveZ.keys = keyframes;

        GetComponent<SpriteRenderer>().flipX = Random.Range(0f, 1f) < 0.5;
        GetComponent<SpriteRenderer>().flipY = Random.Range(0f, 1f) < 0.5;

        _duration = Random.Range(durationRange.x, durationRange.y);
        _spriteRenderer = GetComponent<SpriteRenderer>();

        transform.localScale *= Random.Range(0.8f, 1.2f);

        _timeStart = Time.time;
    }

    private void Update()
    {
        var t = Time.time - _timeStart;
        var xFin = utilies.GetCameraBounds(_camera).x * 0.06f;
        var pos = new Vector3(
            _startPoint.x + xFin * moveCurveX.Evaluate(t * speed),
            _startPoint.y - finalPosY * moveCurveY.Evaluate(t * speed),
            0f);
        var rotation = transform.rotation;
        var angle = Quaternion.Euler(rotation.x, rotation.y,
            45f * rotateCurveZ.Evaluate(t * speed));
        transform.SetPositionAndRotation(pos, angle);

        if (t > _duration)
        {
            var color = _spriteRenderer.color;
            color.a = 1 - moveCurveY.Evaluate((t - _duration) * speed * 1.5f);
            _spriteRenderer.color = color;
        }

        if (t > _duration + 1 / (speed * 1.5f))
            Destroy(gameObject);
    }
}