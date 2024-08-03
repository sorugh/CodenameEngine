package source.funkin.backend.scripting.events;

final class AmountEvent extends CancellableEvent {
	/**
	 * Amount
	 */
	public var amount:Int;

	/**
	 * The health icon
	 */
	public var healthIcon:HealthIcon;
}