using UnityEngine;

public class Autosave : MonoBehaviour
{
    [Range(1, 600)] public int intervalSeconds = 4;
    [SerializeField] public DataStorage dataStorage;    private float _startTime;

    private void Start()
    {
        _startTime = Time.time;
    }

    private void Update()
    {
        if (Time.time - _startTime > intervalSeconds)
        {
            _startTime = Time.time;
            dataStorage.user.Save();
        }
    }
}