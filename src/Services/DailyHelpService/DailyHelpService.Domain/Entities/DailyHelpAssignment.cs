namespace DailyHelpService.Domain.Entities;

public class DailyHelpAssignment : BaseEntity
{
    public Guid StaffId { get; private set; }
    public Guid FlatId { get; private set; }
    public Guid SocietyId { get; private set; }
    public string WorkingDays { get; private set; } = "Mon,Tue,Wed,Thu,Fri,Sat";
    public TimeOnly? InTime { get; private set; }
    public TimeOnly? OutTime { get; private set; }
    public bool IsActive { get; private set; } = true;
    
    public virtual DailyHelpStaff Staff { get; private set; } = null!;

    private DailyHelpAssignment() { }

    public static DailyHelpAssignment Create(Guid staffId, Guid flatId, Guid societyId, string workingDays, TimeOnly? inTime, TimeOnly? outTime)
    {
        if (string.IsNullOrWhiteSpace(workingDays)) throw new ArgumentException("Working days are required.");

        return new DailyHelpAssignment
        {
            StaffId = staffId,
            FlatId = flatId,
            SocietyId = societyId,
            WorkingDays = workingDays.Trim(),
            InTime = inTime,
            OutTime = outTime
        };
    }

    public void UpdateSchedule(string workingDays, TimeOnly? inTime, TimeOnly? outTime)
    {
        WorkingDays = workingDays.Trim();
        InTime = inTime;
        OutTime = outTime;
        UpdatedAt = DateTimeOffset.UtcNow;
    }

    public void Deactivate() { IsActive = false; UpdatedAt = DateTimeOffset.UtcNow; }
}