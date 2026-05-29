namespace SmartTrip.Application.Configurations
{
    public class GoogleAuthSettings
    {
        public GoogleClientIds GoogleClientIds { get; set; } = new();
    }

    public class GoogleClientIds
    {
        public string Web { get; set; } = string.Empty;
        public string Android { get; set; } = string.Empty;
        public string Ios { get; set; } = string.Empty;

        // Helper để lấy danh sách tất cả ID dùng cho việc verify
        public IEnumerable<string> GetAllIds()
        {
            return new[] { Web, Android, Ios }.Where(id => !string.IsNullOrEmpty(id));
        }
    }
}
